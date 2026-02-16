import Foundation

struct ReplacementRule: Identifiable, Codable, Equatable {
    var id = UUID()
    var find: String
    var replace: String
    var enabled: Bool = true
}

extension ReplacementRule {
    static let defaultRules: [ReplacementRule] = [
        .init(find: "arroba", replace: "@"),
        .init(find: "hashtag", replace: "#"),
        .init(find: "guion bajo", replace: "_"),
    ]
}
