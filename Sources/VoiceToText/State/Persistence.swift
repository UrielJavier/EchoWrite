import Foundation

extension AppState {
    private enum Keys {
        static let mode = "mode"
        static let model = "model"
        static let language = "language"
        static let translateToEnglish = "translateToEnglish"
        static let output = "output"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let startSound = "startSound"
        static let stopSound = "stopSound"
        static let notifyOnComplete = "notifyOnComplete"
        static let promptContext = "promptContext"
        static let promptVocabulary = "promptVocabulary"
        static let promptStyle = "promptStyle"
        static let promptPunctuation = "promptPunctuation"
        static let promptInstructions = "promptExtra"
        static let replacementRules = "replacementRules"
        static let history = "history"
        static let stats = "transcriptionStats"
        static let liveChunkInterval = "liveChunkInterval"
        static let liveOverlapMs = "liveOverlapMs"
        static let liveSilenceThreshold = "liveSilenceThreshold"
        static let liveSilenceTimeout = "liveSilenceTimeout"
    }

    private static let defaults = UserDefaults.standard

    func save() {
        Self.defaults.set(mode.rawValue, forKey: Keys.mode)
        Self.defaults.set(model.rawValue, forKey: Keys.model)
        Self.defaults.set(language.rawValue, forKey: Keys.language)
        Self.defaults.set(translateToEnglish, forKey: Keys.translateToEnglish)
        Self.defaults.set(outputMode.rawValue, forKey: Keys.output)
        Self.defaults.set(Int(hotkeyKeyCode), forKey: Keys.hotkeyKeyCode)
        Self.defaults.set(Int(hotkeyModifiers), forKey: Keys.hotkeyModifiers)
        Self.defaults.set(startSound.rawValue, forKey: Keys.startSound)
        Self.defaults.set(stopSound.rawValue, forKey: Keys.stopSound)
        Self.defaults.set(notifyOnComplete, forKey: Keys.notifyOnComplete)
        Self.defaults.set(promptContext, forKey: Keys.promptContext)
        Self.defaults.set(promptVocabulary, forKey: Keys.promptVocabulary)
        Self.defaults.set(promptStyle, forKey: Keys.promptStyle)
        Self.defaults.set(promptPunctuation, forKey: Keys.promptPunctuation)
        Self.defaults.set(promptInstructions, forKey: Keys.promptInstructions)
        if let data = try? JSONEncoder().encode(replacementRules) {
            Self.defaults.set(data, forKey: Keys.replacementRules)
        }
        if let data = try? JSONEncoder().encode(history) {
            Self.defaults.set(data, forKey: Keys.history)
        }
        if let data = try? JSONEncoder().encode(stats) {
            Self.defaults.set(data, forKey: Keys.stats)
        }
        Self.defaults.set(liveChunkInterval, forKey: Keys.liveChunkInterval)
        Self.defaults.set(liveOverlapMs, forKey: Keys.liveOverlapMs)
        Self.defaults.set(liveSilenceThreshold, forKey: Keys.liveSilenceThreshold)
        Self.defaults.set(liveSilenceTimeout, forKey: Keys.liveSilenceTimeout)
    }

    func restore() {
        if let rawMode = Self.defaults.string(forKey: Keys.mode),
           let restoredMode = TranscriptionMode(rawValue: rawMode) { mode = restoredMode }
        if let rawModel = Self.defaults.string(forKey: Keys.model),
           let restoredModel = WhisperModel(rawValue: rawModel) { model = restoredModel }
        if let rawLanguage = Self.defaults.string(forKey: Keys.language),
           let restoredLanguage = Language(rawValue: rawLanguage) { language = restoredLanguage }
        translateToEnglish = Self.defaults.bool(forKey: Keys.translateToEnglish)
        if let rawOutput = Self.defaults.string(forKey: Keys.output),
           let restoredOutput = OutputMode(rawValue: rawOutput) { outputMode = restoredOutput }
        if Self.defaults.object(forKey: Keys.hotkeyKeyCode) != nil {
            hotkeyKeyCode = UInt16(Self.defaults.integer(forKey: Keys.hotkeyKeyCode))
            hotkeyModifiers = UInt(Self.defaults.integer(forKey: Keys.hotkeyModifiers))
        }
        if let rawStartSound = Self.defaults.string(forKey: Keys.startSound),
           let restoredStartSound = SoundEffect(rawValue: rawStartSound) { startSound = restoredStartSound }
        if let rawStopSound = Self.defaults.string(forKey: Keys.stopSound),
           let restoredStopSound = SoundEffect(rawValue: rawStopSound) { stopSound = restoredStopSound }
        notifyOnComplete = Self.defaults.bool(forKey: Keys.notifyOnComplete)
        if let restoredContext = Self.defaults.string(forKey: Keys.promptContext) { promptContext = restoredContext }
        if let restoredVocabulary = Self.defaults.string(forKey: Keys.promptVocabulary) { promptVocabulary = restoredVocabulary }
        if let restoredStyle = Self.defaults.string(forKey: Keys.promptStyle) { promptStyle = restoredStyle }
        if let restoredPunctuation = Self.defaults.string(forKey: Keys.promptPunctuation) { promptPunctuation = restoredPunctuation }
        if let restoredInstructions = Self.defaults.string(forKey: Keys.promptInstructions) { promptInstructions = restoredInstructions }
        if let data = Self.defaults.data(forKey: Keys.replacementRules),
           let restoredRules = try? JSONDecoder().decode([ReplacementRule].self, from: data) {
            replacementRules = restoredRules
        }
        if let data = Self.defaults.data(forKey: Keys.history),
           let restoredEntries = try? JSONDecoder().decode([TranscriptionEntry].self, from: data) {
            history = restoredEntries
        }
        if let data = Self.defaults.data(forKey: Keys.stats),
           let restoredStats = try? JSONDecoder().decode(TranscriptionStats.self, from: data) {
            stats = restoredStats
        }
        if Self.defaults.object(forKey: Keys.liveChunkInterval) != nil {
            liveChunkInterval = Self.defaults.double(forKey: Keys.liveChunkInterval)
        }
        if Self.defaults.object(forKey: Keys.liveOverlapMs) != nil {
            liveOverlapMs = Self.defaults.integer(forKey: Keys.liveOverlapMs)
        }
        if Self.defaults.object(forKey: Keys.liveSilenceThreshold) != nil {
            liveSilenceThreshold = Self.defaults.double(forKey: Keys.liveSilenceThreshold)
        }
        if Self.defaults.object(forKey: Keys.liveSilenceTimeout) != nil {
            liveSilenceTimeout = Self.defaults.double(forKey: Keys.liveSilenceTimeout)
        }
    }
}
