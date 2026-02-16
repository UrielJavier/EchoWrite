import Foundation

struct TranscriptionEntry: Identifiable, Codable {
    let id: UUID
    let text: String
    let date: Date
    var durationSeconds: Int?
    var wordCount: Int?
    var mode: String?
    var wasTranslated: Bool?

    init(text: String, date: Date = Date(), durationSeconds: Int? = nil, wordCount: Int? = nil, mode: String? = nil, wasTranslated: Bool? = nil) {
        self.id = UUID()
        self.text = text
        self.date = date
        self.durationSeconds = durationSeconds
        self.wordCount = wordCount
        self.mode = mode
        self.wasTranslated = wasTranslated
    }
}
