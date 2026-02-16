import Foundation

struct TranscriptionStats: Codable {
    var totalSeconds: Int = 0
    var totalWords: Int = 0
    var totalTranslations: Int = 0
    var totalSessions: Int = 0

    var totalMinutes: Double { Double(totalSeconds) / 60.0 }

    /// Estimated time saved vs typing at ~40 WPM
    var timeSavedMinutes: Double {
        max(0, Double(totalWords) / 40.0 - totalMinutes)
    }

    mutating func record(seconds: Int, text: String, translated: Bool) {
        totalSeconds += seconds
        totalWords += text.split(whereSeparator: \.isWhitespace).count
        if translated { totalTranslations += 1 }
        totalSessions += 1
    }
}
