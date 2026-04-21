import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: PermissionStore

    private var perms: ClaudeSettings.Permissions {
        store.settings.permissions ?? ClaudeSettings.Permissions()
    }
    private var allow: [String] { perms.allow ?? [] }
    private var ask: [String] { perms.ask ?? [] }
    private var deny: [String] { perms.deny ?? [] }
    private var dirs: [String] { perms.additionalDirectories ?? [] }

    /// How many currently-allowed rules are at each risk level.
    private var allowRiskCounts: [RiskLevel: Int] {
        var m: [RiskLevel: Int] = [:]
        for rule in allow {
            let r = CommandCatalog.risk(for: rule)
            m[r, default: 0] += 1
        }
        return m
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "当前权限概览",
                              subtitle: "实时读取 ~/.claude/settings.json")

                statsRow

                if store.expiresAt != nil {
                    Card { timerBanner }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("快速授权").font(.headline)
                            Spacer()
                            Text("一键切换到常用方案").font(.caption).foregroundColor(.secondary)
                        }
                        presetsGrid
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("一键操作").font(.headline)
                        HStack(spacing: 10) {
                            actionButton(icon: "arrow.uturn.backward",
                                         label: "恢复最近快照",
                                         tint: .blue) { store.restoreLatestSnapshot() }
                            actionButton(icon: "bolt.fill",
                                         label: "全量允许",
                                         tint: .orange) {
                                PresetCatalog.all.first { $0.id == "allow_all" }?.apply(store)
                            }
                            actionButton(icon: "xmark.octagon",
                                         label: "清空所有",
                                         tint: .red) { store.clearAllRules() }
                        }
                    }
                }

                if !allow.isEmpty || !ask.isEmpty || !deny.isEmpty {
                    Card { currentRulesDetail }
                }
            }
            .padding(20)
        }
    }

    // MARK: parts

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "允许", value: allow.count, color: .green, systemImage: "checkmark.circle.fill")
            statCard(title: "询问", value: ask.count, color: .yellow, systemImage: "questionmark.circle.fill")
            statCard(title: "拒绝", value: deny.count, color: .red, systemImage: "xmark.octagon.fill")
            statCard(title: "授权目录", value: dirs.count, color: .blue, systemImage: "folder.fill")
        }
    }

    private func statCard(title: String, value: Int, color: Color, systemImage: String) -> some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundColor(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(value)").font(.title.bold())
                    Text(title).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    private var timerBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer").foregroundColor(.orange).font(.title2)
            VStack(alignment: .leading) {
                Text("定时授权生效中").font(.headline)
                if let t = store.expiresAt {
                    Text("将于 \(t.formatted(date: .abbreviated, time: .standard)) 自动恢复快照")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            Button("取消") { store.cancelExpiration() }
                .buttonStyle(.bordered)
        }
    }

    private var presetsGrid: some View {
        let cols = [GridItem(.adaptive(minimum: 220), spacing: 10)]
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(PresetCatalog.all) { p in
                Button { p.apply(store) } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Text(p.emoji).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.title).font(.body.bold())
                            Text(p.summary).font(.caption).foregroundColor(.secondary)
                                .lineLimit(2).multilineTextAlignment(.leading)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.secondary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.subtleBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func actionButton(icon: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.15))
            )
            .foregroundColor(tint)
        }
        .buttonStyle(.plain)
    }

    private var currentRulesDetail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("已配置规则").font(.headline)
            rulesSection("允许", rules: allow, color: .green)
            rulesSection("询问", rules: ask, color: .yellow)
            rulesSection("拒绝", rules: deny, color: .red)
        }
    }

    private func rulesSection(_ title: String, rules: [String], color: Color) -> some View {
        Group {
            if !rules.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle().fill(color).frame(width: 8, height: 8)
                        Text("\(title) · \(rules.count)").font(.caption.bold()).foregroundColor(color)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(rules, id: \.self) { r in
                                Text(r)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(color.opacity(0.12))
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
}

