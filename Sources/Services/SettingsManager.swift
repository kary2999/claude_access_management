import Foundation

enum SettingsManagerError: Error {
    case fileNotFound
    case decodeFailed(String)
}

final class SettingsManager {
    static let shared = SettingsManager()

    var settingsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
    }

    var snapshotsDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/access-manager/snapshots")
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return e
    }()

    func read() throws -> ClaudeSettings {
        let url = settingsURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ClaudeSettings(permissions: .init(allow: [], deny: [], ask: [], additionalDirectories: []))
        }
        let data = try Data(contentsOf: url)
        if data.isEmpty {
            return ClaudeSettings(permissions: .init(allow: [], deny: [], ask: [], additionalDirectories: []))
        }
        // Preserve unknown keys by merging manually
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SettingsManagerError.decodeFailed("root not object")
        }
        let perms = (root["permissions"] as? [String: Any]) ?? [:]
        var parsed = ClaudeSettings(permissions: .init(
            allow: perms["allow"] as? [String] ?? [],
            deny: perms["deny"] as? [String] ?? [],
            ask: perms["ask"] as? [String] ?? [],
            additionalDirectories: perms["additionalDirectories"] as? [String] ?? [],
            defaultMode: perms["defaultMode"] as? String
        ))
        parsed.skipDangerousModePermissionPrompt = root["skipDangerousModePermissionPrompt"] as? Bool
        return parsed
    }

    func write(_ settings: ClaudeSettings) throws {
        let url = settingsURL
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)

        var root: [String: Any] = [:]
        if FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            root = obj
        }
        var perms: [String: Any] = (root["permissions"] as? [String: Any]) ?? [:]
        perms["allow"] = settings.permissions?.allow ?? []
        perms["deny"] = settings.permissions?.deny ?? []
        perms["ask"] = settings.permissions?.ask ?? []
        perms["additionalDirectories"] = settings.permissions?.additionalDirectories ?? []
        if let mode = settings.permissions?.defaultMode, !mode.isEmpty {
            perms["defaultMode"] = mode
        } else {
            perms.removeValue(forKey: "defaultMode")
        }
        root["permissions"] = perms

        // Top-level flag that suppresses the bypass-mode confirmation.
        if let skip = settings.skipDangerousModePermissionPrompt {
            root["skipDangerousModePermissionPrompt"] = skip
        } else {
            root.removeValue(forKey: "skipDangerousModePermissionPrompt")
        }

        let data = try JSONSerialization.data(withJSONObject: root,
                                              options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Snapshots

    func listSnapshots() -> [Snapshot] {
        let fm = FileManager.default
        try? fm.createDirectory(at: snapshotsDir, withIntermediateDirectories: true)
        let items = (try? fm.contentsOfDirectory(at: snapshotsDir,
                                                 includingPropertiesForKeys: nil)) ?? []
        let decoder = JSONDecoder()
        return items.compactMap { url -> Snapshot? in
            guard url.pathExtension == "json",
                  let d = try? Data(contentsOf: url),
                  let s = try? decoder.decode(Snapshot.self, from: d) else { return nil }
            return s
        }.sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func saveSnapshot(label: String) throws -> Snapshot {
        let current = try read()
        let snap = Snapshot(createdAt: Date(), label: label, settings: current)
        try FileManager.default.createDirectory(at: snapshotsDir, withIntermediateDirectories: true)
        let url = snapshotsDir.appendingPathComponent("\(snap.id.uuidString).json")
        let data = try encoder.encode(snap)
        try data.write(to: url, options: .atomic)
        return snap
    }

    func deleteSnapshot(_ snap: Snapshot) {
        let url = snapshotsDir.appendingPathComponent("\(snap.id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
    }

    func restore(_ snap: Snapshot) throws {
        try write(snap.settings)
    }
}
