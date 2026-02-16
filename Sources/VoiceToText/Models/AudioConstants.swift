import Foundation

enum AudioConstants {
    static let maxExpectedEnergy: Float = 0.05

    static var modelsDirectory: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.voicetotext/models"
    }

    static func computeLevel(sum: Float, count: Int) -> Float {
        let avg = count > 0 ? sum / Float(count) : 0
        return min(avg / maxExpectedEnergy, 1.0)
    }
}
