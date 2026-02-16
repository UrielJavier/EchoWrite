import AppKit

enum Language: String, CaseIterable {
    case auto = "auto"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case russian = "ru"
    case arabic = "ar"
    case hindi = "hi"
    case dutch = "nl"
    case polish = "pl"
    case turkish = "tr"

    var label: String {
        switch self {
        case .auto:       return "Auto"
        case .english:    return "English"
        case .spanish:    return "Español"
        case .french:     return "Français"
        case .german:     return "Deutsch"
        case .italian:    return "Italiano"
        case .portuguese: return "Português"
        case .chinese:    return "中文"
        case .japanese:   return "日本語"
        case .korean:     return "한국어"
        case .russian:    return "Русский"
        case .arabic:     return "العربية"
        case .hindi:      return "हिन्दी"
        case .dutch:      return "Nederlands"
        case .polish:     return "Polski"
        case .turkish:    return "Türkçe"
        }
    }
}

enum TranscriptionMode: String, CaseIterable {
    case live = "Live"
    case batch = "Batch"
}

enum OutputMode: String, CaseIterable {
    case typeText = "Type"
    case clipboard = "Clipboard"
}

enum SoundEffect: String, CaseIterable {
    case none = "None"
    case tink = "Tink"
    case pop = "Pop"
    case glass = "Glass"
    case ping = "Ping"
    case purr = "Purr"
    case morse = "Morse"
    case hero = "Hero"
    case funk = "Funk"
    case bottle = "Bottle"
    case blow = "Blow"
    case frog = "Frog"
    case basso = "Basso"
    case sosumi = "Sosumi"
    case submarine = "Submarine"

    func play() {
        guard self != .none else { return }
        NSSound(named: NSSound.Name(rawValue))?.play()
    }
}

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case models = "Models"
    case prompt = "Prompt"
    case replacements = "Replacements"
    case sounds = "Sounds"
    case recording = "Recording"
    case dashboard = "Dashboard"
    case history = "History"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general:      return "gearshape"
        case .models:       return "cube.box"
        case .prompt:       return "text.quote"
        case .replacements: return "arrow.2.squarepath"
        case .sounds:       return "speaker.wave.2"
        case .recording:    return "waveform"
        case .dashboard:    return "chart.bar"
        case .history:      return "clock.arrow.circlepath"
        case .about:        return "info.circle"
        }
    }
}
