import Foundation
import SwiftUI
import Combine

final class PermissionStore: ObservableObject {
    @Published var settings: ClaudeSettings = ClaudeSettings(
        permissions: ClaudeSettings.Permissions(allow: [], deny: [], ask: [], additionalDirectories: [])
    )
    @Published var snapshots: [Snapshot] = []
    @Published var expiresAt: Date? = nil
    @Published var pendingRestoreSnapshotID: UUID? = nil
    @Published var errorMessage: String? = nil

    private var timer: Timer?
    private let defaults = UserDefaults.standard
    private let kExpiresAt = "cam.expiresAt"
    private let kRestoreID = "cam.restoreSnapshotID"

    func load() {
        do {
            settings = try SettingsManager.shared.read()
            snapshots = SettingsManager.shared.listSnapshots()
            if let t = defaults.object(forKey: kExpiresAt) as? Date {
                expiresAt = t
                if let idStr = defaults.string(forKey: kRestoreID), let uuid = UUID(uuidString: idStr) {
                    pendingRestoreSnapshotID = uuid
                }
                scheduleTimer()
            }
        } catch {
            errorMessage = "读取 settings 失败: \(error)"
        }
    }

    func save() {
        do {
            try SettingsManager.shared.write(settings)
        } catch {
            errorMessage = "保存失败: \(error)"
        }
    }

    // MARK: Allow/Deny/Ask toggles

    enum Bucket { case allow, deny, ask }

    func state(of rule: String) -> Bucket? {
        let p = settings.permissions
        if p?.allow?.contains(rule) == true { return .allow }
        if p?.deny?.contains(rule) == true { return .deny }
        if p?.ask?.contains(rule) == true { return .ask }
        return nil
    }

    func set(_ rule: String, to bucket: Bucket?) {
        var p = settings.permissions ?? ClaudeSettings.Permissions()
        p.allow?.removeAll(where: { $0 == rule })
        p.deny?.removeAll(where: { $0 == rule })
        p.ask?.removeAll(where: { $0 == rule })
        switch bucket {
        case .allow: p.allow = (p.allow ?? []) + [rule]
        case .deny:  p.deny = (p.deny ?? []) + [rule]
        case .ask:   p.ask = (p.ask ?? []) + [rule]
        case .none:  break
        }
        settings.permissions = p
        save()
    }

    // MARK: defaultMode (Claude Code 顶层开关)

    enum Mode: String, CaseIterable, Identifiable {
        case `default` = "default"
        case acceptEdits = "acceptEdits"
        case plan = "plan"
        case bypassPermissions = "bypassPermissions"
        var id: String { rawValue }
        var label: String {
            switch self {
            case .`default`:         return "默认（按规则询问）"
            case .acceptEdits:       return "自动接受文件编辑"
            case .plan:              return "Plan 模式（只读）"
            case .bypassPermissions: return "全量放行（YOLO）"
            }
        }
        var emoji: String {
            switch self {
            case .`default`:         return "⚖️"
            case .acceptEdits:       return "✍️"
            case .plan:              return "🗺️"
            case .bypassPermissions: return "🔥"
            }
        }
    }

    var currentMode: Mode {
        guard let raw = settings.permissions?.defaultMode,
              let m = Mode(rawValue: raw) else { return .default }
        return m
    }

    func setMode(_ mode: Mode) {
        takeAutoSnapshotIfNeeded(label: "auto-before-mode-change")
        var p = settings.permissions ?? ClaudeSettings.Permissions()
        p.defaultMode = (mode == .default) ? nil : mode.rawValue
        settings.permissions = p
        save()
    }

    // MARK: Bulk / Presets

    /// Replace all three buckets at once, preserving additionalDirectories.
    func applyBulk(allow: [String], ask: [String], deny: [String]) {
        takeAutoSnapshotIfNeeded(label: "auto-before-bulk")
        var p = settings.permissions ?? ClaudeSettings.Permissions()
        p.allow = allow
        p.ask = ask
        p.deny = deny
        settings.permissions = p
        save()
    }

    func clearAllRules() {
        takeAutoSnapshotIfNeeded(label: "auto-before-clear")
        var p = settings.permissions ?? ClaudeSettings.Permissions()
        p.allow = []
        p.ask = []
        p.deny = []
        settings.permissions = p
        save()
    }

    func restoreLatestSnapshot() {
        guard let latest = snapshots.first else {
            errorMessage = "还没有任何快照，先去「快照」页保存一个。"
            return
        }
        restore(latest)
    }

    private var autoSnapshotThrottleUntil: Date = .distantPast
    /// Keep a safety net snapshot before every destructive bulk op, but at most once per 60s.
    private func takeAutoSnapshotIfNeeded(label: String) {
        guard Date() > autoSnapshotThrottleUntil else { return }
        autoSnapshotThrottleUntil = Date().addingTimeInterval(60)
        do {
            _ = try SettingsManager.shared.saveSnapshot(label: label)
            snapshots = SettingsManager.shared.listSnapshots()
        } catch { /* non-fatal */ }
    }

    // MARK: Directories

    func addDirectory(_ path: String) {
        var p = settings.permissions ?? ClaudeSettings.Permissions()
        var dirs = p.additionalDirectories ?? []
        if !dirs.contains(path) { dirs.append(path) }
        p.additionalDirectories = dirs
        settings.permissions = p
        save()
    }

    func removeDirectory(_ path: String) {
        var p = settings.permissions ?? ClaudeSettings.Permissions()
        p.additionalDirectories?.removeAll(where: { $0 == path })
        settings.permissions = p
        save()
    }

    // MARK: Snapshots

    func snapshot(label: String) {
        do {
            _ = try SettingsManager.shared.saveSnapshot(label: label)
            snapshots = SettingsManager.shared.listSnapshots()
        } catch {
            errorMessage = "快照失败: \(error)"
        }
    }

    func restore(_ snap: Snapshot) {
        do {
            try SettingsManager.shared.restore(snap)
            load()
        } catch {
            errorMessage = "恢复失败: \(error)"
        }
    }

    func deleteSnapshot(_ snap: Snapshot) {
        SettingsManager.shared.deleteSnapshot(snap)
        snapshots = SettingsManager.shared.listSnapshots()
    }

    // MARK: Expiration Timer

    func startExpiration(minutes: Int, restoreTo snapID: UUID) {
        expiresAt = Date().addingTimeInterval(TimeInterval(minutes * 60))
        pendingRestoreSnapshotID = snapID
        defaults.set(expiresAt, forKey: kExpiresAt)
        defaults.set(snapID.uuidString, forKey: kRestoreID)
        scheduleTimer()
    }

    func cancelExpiration() {
        expiresAt = nil
        pendingRestoreSnapshotID = nil
        defaults.removeObject(forKey: kExpiresAt)
        defaults.removeObject(forKey: kRestoreID)
        timer?.invalidate(); timer = nil
    }

    private func scheduleTimer() {
        timer?.invalidate()
        guard let t = expiresAt else { return }
        let interval = max(1, t.timeIntervalSinceNow)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.fire() }
        }
    }

    private func fire() {
        guard let snapID = pendingRestoreSnapshotID,
              let snap = snapshots.first(where: { $0.id == snapID }) else {
            cancelExpiration(); return
        }
        restore(snap)
        cancelExpiration()
    }
}
