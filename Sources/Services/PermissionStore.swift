import Foundation
import SwiftUI
import Combine

@MainActor
final class PermissionStore: ObservableObject {
    @Published var settings = ClaudeSettings(permissions: .init(allow: [], deny: [], ask: [], additionalDirectories: []))
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
        var p = settings.permissions ?? .init()
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

    // MARK: Directories

    func addDirectory(_ path: String) {
        var p = settings.permissions ?? .init()
        var dirs = p.additionalDirectories ?? []
        if !dirs.contains(path) { dirs.append(path) }
        p.additionalDirectories = dirs
        settings.permissions = p
        save()
    }

    func removeDirectory(_ path: String) {
        var p = settings.permissions ?? .init()
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
            Task { @MainActor in self?.fire() }
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
