import Foundation

struct ClaudeSettings: Codable, Equatable {
    var permissions: Permissions?
    /// Top-level flag that suppresses Claude Code's bypass-mode
    /// confirmation prompt when defaultMode == "bypassPermissions".
    /// Lives at the root of settings.json, not inside permissions.
    var skipDangerousModePermissionPrompt: Bool? = nil

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
