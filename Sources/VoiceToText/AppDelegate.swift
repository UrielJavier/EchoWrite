import SwiftUI
import UserNotifications
import whisper

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let recorder = AudioRecorder()
    let transcriber = WhisperTranscriber()
    var hotkeyManager: HotkeyManager?
    var liveTask: Task<Void, Never>?
    private var downloadManager: ModelDownloadManager?
    private var settingsWindow: NSWindow?
    private var floatingWindow: NSPanel?
    private var liveSessionText = ""
    private var recordingTimer: Task<Void, Never>?
    private var windowDelegate: SettingsWindowDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        downloadManager = ModelDownloadManager(appState: appState) { [weak self] model in
            await self?.loadModel(model)
        }
        appState.restore()
        setupHotkey()
        Task { await loadModel() }
        // Only prompt for accessibility once — don't nag on every launch.
        if !TextSimulator.hasAccessibilityPermission && !UserDefaults.standard.bool(forKey: "accessibilityPrompted") {
            UserDefaults.standard.set(true, forKey: "accessibilityPrompted")
            TextSimulator.requestAccessibilityPermission()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.save()
        liveTask?.cancel()
        recorder.shutdown()
        // Exit immediately to avoid ggml_abort during async teardown.
        // The OS reclaims all process memory — no leak.
        _exit(0)
    }

    func saveSettings() { appState.save() }

    private func outputText(_ text: String) {
        guard !text.isEmpty else { return }
        let processed = appState.applyReplacements(text)
        guard !processed.isEmpty else { return }
        switch appState.outputMode {
        case .typeText:  TextSimulator.simulateTyping(text: processed)
        case .clipboard: TextSimulator.copyToClipboard(text: processed)
        }
    }

    private func playStartSound() { appState.startSound.play() }
    private func playStopSound() { appState.stopSound.play() }

    // MARK: - Recording Timer & Silence Detection

    private func startRecordingTimer() {
        appState.recordingSeconds = 0
        appState.audioLevel = 0
        appState.silenceCountdown = 0
        recordingTimer = Task {
            var ticks = 0
            var silenceTicks = 0
            let thresholdLevel = Float(appState.liveSilenceThreshold / Double(AudioConstants.maxExpectedEnergy))
            let maxSilenceTicks = max(1, Int(appState.liveSilenceTimeout / 0.2))
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
                ticks += 1
                appState.audioLevel = recorder.currentLevel
                if ticks % 5 == 0 {
                    appState.recordingSeconds += 1
                }
                if appState.mode == .batch {
                    if recorder.currentLevel < thresholdLevel {
                        silenceTicks += 1
                        let remaining = max(0, maxSilenceTicks - silenceTicks)
                        appState.silenceCountdown = Int(ceil(Double(remaining) * 0.2))
                        if silenceTicks >= maxSilenceTicks {
                            appState.silenceCountdown = 0
                            await stopBatchRecording()
                            return
                        }
                    } else {
                        silenceTicks = 0
                        appState.silenceCountdown = 0
                    }
                }
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.cancel()
        recordingTimer = nil
        appState.silenceCountdown = 0
        if !recorder.isMonitoring { appState.audioLevel = 0 }
    }

    // MARK: - Level Monitoring (for Settings calibration)

    private var monitoringTimer: Task<Void, Never>?

    func startAudioMonitoring() {
        guard monitoringTimer == nil else { return }
        Task {
            let granted = await AudioRecorder.requestPermission()
            guard granted else { return }
            do {
                try recorder.startLevelMonitoring()
                monitoringTimer = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        guard !Task.isCancelled else { return }
                        appState.audioLevel = recorder.currentLevel
                    }
                }
            } catch {
                appState.lastError = "Audio monitoring failed: \(error.localizedDescription)"
            }
        }
    }

    func stopAudioMonitoring() {
        monitoringTimer?.cancel()
        monitoringTimer = nil
        recorder.stopLevelMonitoring()
        if !appState.isRecording { appState.audioLevel = 0 }
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkeyManager = HotkeyManager { [weak self] in
            guard let self else { return }
            Task { @MainActor in await self.toggleRecording() }
        }
        hotkeyManager?.keyCode = appState.hotkeyKeyCode
        hotkeyManager?.modifiers = NSEvent.ModifierFlags(rawValue: appState.hotkeyModifiers)
        hotkeyManager?.register()
    }

    func applyHotkey() {
        hotkeyManager?.keyCode = appState.hotkeyKeyCode
        hotkeyManager?.modifiers = NSEvent.ModifierFlags(rawValue: appState.hotkeyModifiers)
    }

    // MARK: - Notifications

    private func sendNotification(text: String) {
        guard appState.notifyOnComplete,
              Bundle.main.bundlePath.hasSuffix(".app") else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Transcription Complete"
            content.body = String(text.prefix(100))
            content.sound = .default
            let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(req)
        }
    }

    // MARK: - Downloads (delegated to ModelDownloadManager)

    func downloadAndLoadModel(_ model: WhisperModel) {
        downloadManager?.download(model)
    }

    func cancelDownload() {
        downloadManager?.cancel()
    }

    // MARK: - Floating Recording Window

    private func showFloatingWindow() {
        guard appState.showFloatingWindow else { return }
        guard floatingWindow == nil else {
            floatingWindow?.orderFront(nil)
            return
        }

        let view = FloatingRecordingView(appState: appState)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

        let controller = NSHostingController(rootView: view)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 60),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = controller
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hasShadow = true

        // Restore saved position or default to bottom-center
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "floatingWindowX") != nil {
            let x = defaults.double(forKey: "floatingWindowX")
            let y = defaults.double(forKey: "floatingWindowY")
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 125
            let y = screenFrame.minY + 60
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        floatingWindow = panel
    }

    private func hideFloatingWindow() {
        guard let panel = floatingWindow else { return }
        // Save position
        let frame = panel.frame
        UserDefaults.standard.set(Double(frame.origin.x), forKey: "floatingWindowX")
        UserDefaults.standard.set(Double(frame.origin.y), forKey: "floatingWindowY")
        panel.close()
        floatingWindow = nil
    }

    // MARK: - Settings Window

    private func activateApp() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func deactivateAppIfNoWindows() {
        let hasVisible = settingsWindow?.isVisible ?? false
        if !hasVisible {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func openSettings(section: SettingsSection = .general) {
        appState.selectedSettingsSection = section
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            activateApp()
            return
        }
        let view = SettingsView(
            state: appState,
            onSave: { [weak self] in self?.appState.save() },
            onHotkeyChange: { [weak self] in self?.applyHotkey() },
            onPauseHotkey: { [weak self] in self?.hotkeyManager?.isEnabled = false },
            onResumeHotkey: { [weak self] in self?.hotkeyManager?.isEnabled = true },
            onStartMonitoring: { [weak self] in self?.startAudioMonitoring() },
            onStopMonitoring: { [weak self] in self?.stopAudioMonitoring() },
            onDownloadModel: { [weak self] model in self?.downloadAndLoadModel(model) },
            onLoadModel: { [weak self] model in
                guard let self else { return }
                Task { await self.loadModel(model) }
            },
            onUnloadModel: { [weak self] in
                guard let self else { return }
                Task { await self.unloadModel() }
            },
            onCancelDownload: { [weak self] in self?.cancelDownload() }
        )
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let windowWidth = screen.width * 3 / 5
        let windowHeight = screen.height * 0.75

        let delegate = SettingsWindowDelegate { [weak self] in self?.deactivateAppIfNoWindows() }
        windowDelegate = delegate

        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "VoiceToText"
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.minSize = NSSize(width: 500, height: 350)
        window.level = .normal
        window.delegate = delegate
        window.setContentSize(NSSize(width: windowWidth, height: windowHeight))
        window.center()
        window.makeKeyAndOrderFront(nil)
        activateApp()
        settingsWindow = window
    }

    func openHistory() {
        openSettings(section: .history)
    }

    // MARK: - Model Loading

    func loadModel(_ model: WhisperModel? = nil) async {
        let selected = model ?? appState.model
        await MainActor.run {
            appState.isModelLoaded = false
            appState.isLoadingModel = true
            appState.status = .idle
        }
        do {
            try await transcriber.loadModel(fileName: selected.fileName)
            await MainActor.run {
                appState.model = selected
                appState.isModelLoaded = true
                appState.isLoadingModel = false
                appState.lastError = nil
            }
        } catch {
            await MainActor.run {
                appState.isLoadingModel = false
                appState.lastError = error.localizedDescription
                appState.status = .error
            }
        }
    }

    func unloadModel() async {
        await transcriber.cleanup()
        appState.isModelLoaded = false
    }

    // MARK: - Recording

    func toggleRecording() async {
        guard !appState.isTranscribing, appState.isModelLoaded else { return }
        if appState.isRecording {
            if appState.mode == .live { await stopLiveRecording() }
            else { await stopBatchRecording() }
        } else {
            let granted = await AudioRecorder.requestPermission()
            guard granted else {
                appState.lastError = "Microphone permission denied"
                appState.status = .error
                return
            }
            do {
                playStartSound()
                try await Task.sleep(nanoseconds: 250_000_000)
                try recorder.startRecording()
                appState.status = .recording
                appState.lastError = nil
                startRecordingTimer()
                showFloatingWindow()
                if appState.mode == .live {
                    liveSessionText = ""
                    startLiveLoop()
                }
            } catch {
                appState.status = .error
                appState.lastError = error.localizedDescription
            }
        }
    }

    private func stopBatchRecording() async {
        hideFloatingWindow()
        stopRecordingTimer()
        let audioData = recorder.stopRecording()
        playStopSound()
        appState.status = .transcribing
        do {
            let text = try await transcriber.transcribe(
                audioData: audioData, language: appState.language.rawValue,
                translate: appState.translateToEnglish,
                initialPrompt: appState.composedPrompt)
            outputText(text)
            appState.status = .idle
            appState.lastError = nil
            appState.addToHistory(text, durationSeconds: appState.recordingSeconds, translated: appState.translateToEnglish)
            sendNotification(text: text)
        } catch {
            appState.status = .error
            appState.lastError = error.localizedDescription
        }
    }

    // MARK: - Live Transcription

    private func startLiveLoop() {
        liveTask = Task.detached { [weak self] in
            var promptTokens: [whisper_token] = []
            var silenceSteps = 0
            let intervalNs: UInt64
            let overlapSamples: Int
            let silenceThreshold: Double
            let silenceTimeout: Double
            if let s = self {
                (intervalNs, overlapSamples, silenceThreshold, silenceTimeout) = await MainActor.run {
                    (UInt64(s.appState.liveChunkInterval * 1_000_000_000),
                     s.appState.liveOverlapMs * 16,
                     s.appState.liveSilenceThreshold,
                     s.appState.liveSilenceTimeout)
                }
            } else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: intervalNs)
                guard !Task.isCancelled, let self else { return }
                let (language, translate, prompt) = await MainActor.run {
                    (self.appState.language.rawValue, self.appState.translateToEnglish, self.appState.composedPrompt)
                }
                let chunk = self.recorder.drainSamples(keeping: overlapSamples)
                guard !chunk.isEmpty else { continue }
                let energy = chunk.reduce(Float(0)) { $0 + abs($1) } / Float(chunk.count)
                guard energy > Float(silenceThreshold) else {
                    promptTokens.removeAll()
                    silenceSteps += 1
                    let maxSilenceSteps = Int(silenceTimeout / (Double(intervalNs) / 1_000_000_000))
                    if silenceSteps >= max(1, maxSilenceSteps) {
                        await MainActor.run {
                            self.hideFloatingWindow()
                            self.stopRecordingTimer()
                            _ = self.recorder.stopRecording()
                            self.appState.status = .idle
                            self.playStopSound()
                            self.appState.addToHistory(self.liveSessionText, durationSeconds: self.appState.recordingSeconds, translated: self.appState.translateToEnglish)
                            self.sendNotification(text: self.liveSessionText)
                        }
                        return
                    }
                    continue
                }
                silenceSteps = 0
                do {
                    let (text, tokens) = try await self.transcriber.transcribeLive(
                        audioData: chunk, language: language,
                        translate: translate, promptTokens: promptTokens,
                        initialPrompt: prompt)
                    promptTokens = tokens
                    if !text.isEmpty {
                        await MainActor.run {
                            if !self.liveSessionText.isEmpty {
                                self.outputText(" ")
                                self.liveSessionText += " "
                            }
                            self.outputText(text)
                            self.liveSessionText += text
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.appState.lastError = error.localizedDescription
                    }
                }
            }
        }
    }

    private func stopLiveRecording() async {
        hideFloatingWindow()
        stopRecordingTimer()
        liveTask?.cancel()
        await liveTask?.value
        liveTask = nil
        playStopSound()
        let remaining = recorder.stopRecording()
        guard !remaining.isEmpty else {
            appState.addToHistory(liveSessionText, durationSeconds: appState.recordingSeconds, translated: appState.translateToEnglish)
            sendNotification(text: liveSessionText)
            appState.status = .idle
            return
        }
        appState.status = .transcribing
        do {
            let text = try await transcriber.transcribe(
                audioData: remaining, language: appState.language.rawValue,
                translate: appState.translateToEnglish,
                initialPrompt: appState.composedPrompt)
            outputText(text)
            liveSessionText += text
            appState.addToHistory(liveSessionText, durationSeconds: appState.recordingSeconds, translated: appState.translateToEnglish)
            sendNotification(text: liveSessionText)
            appState.status = .idle
            appState.lastError = nil
        } catch {
            appState.addToHistory(liveSessionText, durationSeconds: appState.recordingSeconds, translated: appState.translateToEnglish)
            appState.status = .error
            appState.lastError = error.localizedDescription
        }
    }
}

// MARK: - SettingsWindowDelegate

final class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void
    init(onClose: @escaping () -> Void) { self.onClose = onClose }
    func windowWillClose(_ notification: Notification) { onClose() }
}
