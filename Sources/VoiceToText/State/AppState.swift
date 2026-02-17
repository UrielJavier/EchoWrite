import SwiftUI

@MainActor
@Observable
final class AppState {
    enum Status: String {
        case idle = "Ready"
        case recording = "Recording..."
        case transcribing = "Transcribing..."
        case error = "Error"
    }

    var status: Status = .idle
    var lastError: String?
    var isModelLoaded = false
    var isLoadingModel = false
    var language: Language = .auto
    var translateToEnglish = false
    var mode: TranscriptionMode = .batch
    var model: WhisperModel = .base
    var outputMode: OutputMode = .typeText
    var hotkeyKeyCode: UInt16 = 1
    var hotkeyModifiers: UInt = NSEvent.ModifierFlags([.command, .function]).rawValue
    var startSound: SoundEffect = .pop
    var stopSound: SoundEffect = .funk
    var notifyOnComplete = false
    var showFloatingWindow = true

    // Prompt fields — composed into initial_prompt for whisper
    var promptContext: String = ""
    var promptVocabulary: String = ""
    var promptStyle: String = "Natural, conversacional"
    var promptPunctuation: String = "Usar puntuación correcta: comas, puntos, signos de interrogación"
    var promptInstructions: String = "Ignorar ruido de fondo y silencios"

    // Text replacement rules applied after transcription
    var replacementRules: [ReplacementRule] = ReplacementRule.defaultRules

    func applyReplacements(_ text: String) -> String {
        var result = text
        for rule in replacementRules where rule.enabled && !rule.find.isEmpty {
            result = result.replacingOccurrences(
                of: rule.find, with: rule.replace,
                options: .caseInsensitive
            )
        }
        return result
    }

    var composedPrompt: String {
        var parts: [String] = []
        let fields: [(String, String)] = [
            ("Contexto", promptContext),
            ("Vocabulario", promptVocabulary),
            ("Estilo", promptStyle),
            ("Puntuación", promptPunctuation),
            ("Instrucciones", promptInstructions),
        ]
        for (heading, value) in fields {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { parts.append("# \(heading)\n\(trimmed)") }
        }
        return parts.joined(separator: "\n\n")
    }

    // Live mode tuning
    var liveChunkInterval: Double = 2.0      // seconds between transcriptions
    var liveOverlapMs: Int = 500             // ms of audio kept for context between chunks
    var liveSilenceThreshold: Double = 0.002 // energy below this = silence
    var liveSilenceTimeout: Double = 10.0    // seconds of silence before auto-stop

    var recordingSeconds: Int = 0
    var audioLevel: Float = 0  // 0.0 to 1.0, updated during recording
    var silenceCountdown: Int = 0  // seconds until auto-stop, 0 = not counting

    var modelListVersion = 0
    var isDownloading = false
    var downloadProgress: Double = 0
    var downloadingModel: WhisperModel?
    var history: [TranscriptionEntry] = []
    var stats = TranscriptionStats()
    var selectedSettingsSection: SettingsSection = .general

    var hotkeyLabel: String {
        VoiceToText.hotkeyLabel(keyCode: hotkeyKeyCode, modifiers: NSEvent.ModifierFlags(rawValue: hotkeyModifiers))
    }

    func addToHistory(_ text: String, durationSeconds: Int = 0, translated: Bool = false) {
        let trimmed = applyReplacements(text).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let wc = trimmed.split(whereSeparator: \.isWhitespace).count
        let entry = TranscriptionEntry(
            text: trimmed,
            durationSeconds: durationSeconds,
            wordCount: wc,
            mode: mode.rawValue,
            wasTranslated: translated
        )
        history.insert(entry, at: 0)
        if history.count > 50 { history.removeLast() }
        stats.record(seconds: durationSeconds, text: trimmed, translated: translated)
        save()
    }

    func resetToDefaults() {
        language = .auto
        translateToEnglish = false
        mode = .batch
        outputMode = .typeText
        hotkeyKeyCode = 1
        hotkeyModifiers = NSEvent.ModifierFlags([.command, .function]).rawValue
        startSound = .pop
        stopSound = .funk
        notifyOnComplete = false
        showFloatingWindow = true
        promptContext = ""
        promptVocabulary = ""
        promptStyle = "Natural, conversacional"
        promptPunctuation = "Usar puntuación correcta: comas, puntos, signos de interrogación"
        promptInstructions = "Ignorar ruido de fondo y silencios"
        replacementRules = ReplacementRule.defaultRules
        liveChunkInterval = 2.0
        liveOverlapMs = 500
        liveSilenceThreshold = 0.002
        liveSilenceTimeout = 10.0
    }

    var isRecording: Bool { status == .recording }
    var isTranscribing: Bool { status == .transcribing }

    var statusIcon: String {
        switch status {
        case .idle: return "mic"
        case .recording: return "mic.fill"
        case .transcribing: return "text.bubble"
        case .error: return "exclamationmark.triangle"
        }
    }
}
