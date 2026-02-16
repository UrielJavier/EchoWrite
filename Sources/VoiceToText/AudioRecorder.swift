import AVFoundation
import Foundation

final class AudioRecorder {
    private var audioEngine: AVAudioEngine?
    private var samples: [Float] = []
    private let lock = NSLock()
    private var _currentLevel: Float = 0

    /// Current audio energy level (0.0–1.0), thread-safe.
    var currentLevel: Float {
        lock.lock()
        defer { lock.unlock() }
        return _currentLevel
    }

    var isRecording: Bool {
        audioEngine?.isRunning ?? false
    }

    func startRecording() throws {
        // Stop previous engine if still running from last recording
        if let old = audioEngine {
            old.inputNode.removeTap(onBus: 0)
            old.stop()
            audioEngine = nil
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        let desiredFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!

        let hardwareFormat = inputNode.outputFormat(forBus: 0)

        lock.lock()
        defer { lock.unlock() }
        samples.removeAll(keepingCapacity: true)
        samples.reserveCapacity(16000 * 30) // pre-allocate ~30s at 16kHz

        // Install tap at hardware format, then convert
        let converter = AVAudioConverter(from: hardwareFormat, to: desiredFormat)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] buffer, _ in
            guard let self, let converter else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * desiredFormat.sampleRate / hardwareFormat.sampleRate
            )
            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: desiredFormat,
                frameCapacity: frameCount
            ) else { return }

            var error: NSError?
            var hasData = true
            converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                if hasData {
                    hasData = false
                    outStatus.pointee = .haveData
                    return buffer
                }
                outStatus.pointee = .noDataNow
                return nil
            }

            if error == nil, let channelData = convertedBuffer.floatChannelData {
                let count = Int(convertedBuffer.frameLength)
                let newSamples = Array(UnsafeBufferPointer(start: channelData[0], count: count))
                var sum: Float = 0
                for i in 0..<count { sum += abs(newSamples[i]) }
                let level = AudioConstants.computeLevel(sum: sum, count: count)

                self.lock.lock()
                defer { self.lock.unlock() }
                self._currentLevel = level
                self.samples.append(contentsOf: newSamples)
            }
        }

        engine.prepare()
        try engine.start()
        audioEngine = engine
    }

    /// Returns accumulated samples for transcription, keeping the last `overlapSamples`
    /// in the buffer to avoid cutting words at chunk boundaries (like whisper.cpp's `keep_ms`).
    /// At 16 kHz, 8000 samples = 500 ms of overlap.
    /// Returns empty if not enough audio has accumulated beyond the overlap.
    func drainSamples(keeping overlapSamples: Int = 8000) -> [Float] {
        lock.lock()
        defer { lock.unlock() }

        guard samples.count > overlapSamples else {
            return []  // not enough new audio yet, wait for more
        }

        let drained = samples
        samples = Array(samples.suffix(overlapSamples))
        return drained
    }

    func stopRecording() -> [Float] {
        audioEngine?.inputNode.removeTap(onBus: 0)
        // Don't stop the engine here — stopping causes an audio glitch
        // from hardware reconfiguration. The engine idles silently without
        // a tap and gets stopped on the next startRecording() or shutdown().

        lock.lock()
        defer { lock.unlock() }
        let captured = samples
        samples = [] // release buffer memory when not recording
        return captured
    }

    // MARK: - Level monitoring (no sample accumulation)

    private var monitorEngine: AVAudioEngine?

    var isMonitoring: Bool { monitorEngine?.isRunning ?? false }

    func startLevelMonitoring() throws {
        guard monitorEngine == nil else { return }
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let hardwareFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] buffer, _ in
            guard let self, let channelData = buffer.floatChannelData else { return }
            let count = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<count { sum += abs(channelData[0][i]) }
            let level = AudioConstants.computeLevel(sum: sum, count: count)
            self.lock.lock()
            defer { self.lock.unlock() }
            self._currentLevel = level
        }

        engine.prepare()
        try engine.start()
        monitorEngine = engine
    }

    func stopLevelMonitoring() {
        monitorEngine?.inputNode.removeTap(onBus: 0)
        monitorEngine?.stop()
        monitorEngine = nil
        lock.lock()
        defer { lock.unlock() }
        _currentLevel = 0
    }

    /// Fully stops the audio engine. Call on app termination.
    func shutdown() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        stopLevelMonitoring()
    }

    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
