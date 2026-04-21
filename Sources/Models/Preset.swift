import Foundation

struct Preset: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let emoji: String
    let apply: (PermissionStore) -> Void

    static func == (l: Preset, r: Preset) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

enum PresetCatalog {
    static let all: [Preset] = [
        Preset(
            id: "readonly",
            title: "只读模式",
            summary: "只允许查看类指令（L1 + L2），写入/网络写/破坏性一律拒绝。",
            emoji: "🛡️"
        ) { store in
            store.applyBulk(
                allow: CommandCatalog.all.filter { $0.risk.rawValue <= 2 }.map { $0.rule },
                ask: [],
                deny: CommandCatalog.all.filter { $0.risk.rawValue >= 3 }.map { $0.rule }
            )
        },
        Preset(
            id: "daily",
            title: "日常开发",
            summary: "L1–L3 放行，网络写/破坏性提示确认。推荐默认。",
            emoji: "🧑‍💻"
        ) { store in
            store.applyBulk(
                allow: CommandCatalog.all.filter { $0.risk.rawValue <= 3 }.map { $0.rule },
                ask:   CommandCatalog.all.filter { $0.risk.rawValue >= 4 }.map { $0.rule },
                deny: []
            )
        },
        Preset(
            id: "loose",
            title: "自由模式",
            summary: "L1–L4 放行，只有 L5 破坏性仍需确认。",
            emoji: "🚀"
        ) { store in
            store.applyBulk(
                allow: CommandCatalog.all.filter { $0.risk.rawValue <= 4 }.map { $0.rule },
                ask:   CommandCatalog.all.filter { $0.risk.rawValue == 5 }.map { $0.rule },
                deny: []
            )
        },
        Preset(
            id: "allow_all",
            title: "全量放行",
            summary: "所有内置指令直接 allow（含 L5 破坏性）。⚠️ 自担风险。",
            emoji: "⚡"
        ) { store in
            store.applyBulk(
                allow: CommandCatalog.all.map { $0.rule },
                ask: [], deny: []
            )
        },
        Preset(
            id: "lockdown",
            title: "锁死",
            summary: "所有内置指令 deny。每次都会被询问（实际上拒绝）。",
            emoji: "🔒"
        ) { store in
            store.applyBulk(
                allow: [], ask: [],
                deny: CommandCatalog.all.map { $0.rule }
            )
        }
    ]
}
