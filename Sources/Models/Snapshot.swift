import Foundation

struct ClaudeSettings: Codable, Equatable {
    var permissions: Permissions?

    struct Permissions: Codable, Equatable {
        var allow: [String]?
        var deny: [String]?
        var ask: [String]?
        var additionalDirectories: [String]?
    }
}

struct Snapshot: Codable, Identifiable {
    var id = UUID()
    var createdAt: Date
    var label: String
    var settings: ClaudeSettings
}
