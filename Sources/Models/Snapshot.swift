import Foundation

struct ClaudeSettings: Codable, Equatable {
    var permissions: Permissions?

    struct Permissions: Codable, Equatable {
        var allow: [String]? = nil
        var deny: [String]? = nil
        var ask: [String]? = nil
        var additionalDirectories: [String]? = nil
        /// Claude Code's top-level switch.
        /// "default" | "acceptEdits" | "plan" | "bypassPermissions"
        var defaultMode: String? = nil
    }
}

struct Snapshot: Codable, Identifiable {
    var id = UUID()
    var createdAt: Date
    var label: String
    var settings: ClaudeSettings
}
