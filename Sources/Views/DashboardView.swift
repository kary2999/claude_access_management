import SwiftUI
import AppKit

struct DashboardView: View {
    @EnvironmentObject var store: PermissionStore
    @State private var toast: String? = nil
    @State private var timerMinutes: Int = 30
    @State private var timerTargetSnapID: UUID? = nil

    private func flash(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if toast == msg { toast = nil }
        }
    }

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
        ZStack(alignment: .top) {
            scrollContent
            if let msg = toast { toastView(msg) }
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "当前权限概览",
                              subtitle: "实时读取 ~/.claude/settings.json")

                statsRow
                modeCard

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

                yoloMethodsCard
                timerCard

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("一键操作").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 10)], spacing: 10) {
                            actionButton(icon: "arrow.uturn.backward",
                                         label: "恢复最近快照",
                                         tint: .blue) { store.restoreLatestSnapshot() }
                            actionButton(icon: "xmark.octagon",
                                         label: "清空所有规则",
                                         tint: .red) { store.clearAllRules() }
                        }
                    }
                }

                if !allow.isEmpty || !ask.isEmpty || !deny.isEmpty {
                    Card { currentRulesDetail }
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 32)
        }
    }

    private var yoloMethodsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Text("🔥").font(.title3)
                    Text("YOLO 全放行 · 两种方式").font(.headline)
                    Spacer()
                }
                Text("两种方式效果等价：前者持久化到配置、全局生效；后者只对当次 `claude` 启动生效。")
                    .font(.caption).foregroundColor(.secondary)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("改配置后必须重启 Claude 会话才生效").font(.callout.bold())
                        Text("当前正在运行的 `claude` 进程是在启动时读的配置，settings.json 不会热加载。想立刻生效就用方式 2。")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], spacing: 12) {
                    yoloMethodSettings
                    yoloMethodCLI
                }
            }
        }
    }

    private var yoloMethodSettings: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill").foregroundColor(.accentColor)
                Text("方式 1：写入 settings.json").font(.callout.bold())
                Spacer(minLength: 0)
                if store.currentMode == .bypassPermissions {
                    Text("生效中").font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.2)))
                        .foregroundColor(.green)
                }
            }
            codeBlock(#"{ "permissions": { "defaultMode": "bypassPermissions" } }"#)
            HStack(spacing: 8) {
                Button {
                    store.setMode(.bypassPermissions)
                    flash("已写入 defaultMode=bypassPermissions")
                } label: {
                    Label("一键写入", systemImage: "square.and.pencil")
                }
                .buttonStyle(.borderedProminent)
                Button {
                    store.setMode(.default)
                    flash("已关闭 YOLO")
                } label: {
                    Label("关闭", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .disabled(store.currentMode != .bypassPermissions)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        )
    }

    private var yoloMethodCLI: some View {
        let cmd = "claude --dangerously-skip-permissions"
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "terminal.fill").foregroundColor(.accentColor)
                Text("方式 2：启动时加 CLI flag").font(.callout.bold())
                Spacer(minLength: 0)
            }
            codeBlock(cmd)
            HStack(spacing: 8) {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmd, forType: .string)
                    flash("已复制命令到剪贴板")
                } label: {
                    Label("复制", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                Button {
                    launchInTerminal(cmd)
                } label: {
                    Label("打开终端运行", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        )
    }

    private func codeBlock(_ s: String) -> some View {
        Text(s)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.08))
            )
    }

    private func launchInTerminal(_ command: String) {
        let script = """
        tell application "Terminal"
            activate
            do script "\(command)"
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return }
        var err: NSDictionary?
        appleScript.executeAndReturnError(&err)
        if err == nil {
            flash("已在终端启动")
        } else {
            flash("启动失败，请手动复制命令")
        }
    }

    private var modeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("默认授权模式").font(.headline)
                    Spacer()
                    Text("permissions.defaultMode")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 8)], spacing: 8) {
                    ForEach(PermissionStore.Mode.allCases) { m in
                        let active = store.currentMode == m
                        Button {
                            store.setMode(m)
                            flash("默认模式 → \(m.label)")
                        } label: {
                            HStack(spacing: 6) {
                                Text(m.emoji)
                                Text(m.label).font(.caption.bold())
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(active ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(active ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                            .foregroundColor(active ? .accentColor : .primary)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                if store.currentMode == .bypassPermissions {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text("全量放行已开启。Claude 会跳过所有权限询问。用完记得切回「默认」。")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func toastView(_ msg: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            Text(msg).font(.callout.bold())
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.cardBG)
                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.4), lineWidth: 1)
        )
        .padding(.top, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: parts

    private var statsRow: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
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
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var timerCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("定时授权").font(.headline)
                    Spacer()
                    if store.expiresAt != nil {
                        Text("生效中").font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange.opacity(0.2)))
                            .foregroundColor(.orange)
                    }
                }
                Text("到期后自动恢复到指定快照，避免长期授权泄露。")
                    .font(.caption).foregroundColor(.secondary)

                if let t = store.expiresAt {
                    HStack(spacing: 8) {
                        Image(systemName: "timer").foregroundColor(.orange)
                        Text("将于 \(t.formatted(date: .abbreviated, time: .standard)) 自动恢复")
                            .font(.callout)
                        Spacer()
                        Button("取消") {
                            store.cancelExpiration()
                            flash("定时已取消")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Stepper("有效时间：\(timerMinutes) 分钟",
                                    value: $timerMinutes, in: 1...1440, step: 5)
                            Spacer()
                        }
                        HStack(spacing: 10) {
                            Picker("到期恢复到", selection: $timerTargetSnapID) {
                                Text(store.snapshots.isEmpty ? "先去「快照」页保存一个" : "选择快照…")
                                    .tag(UUID?.none)
                                ForEach(store.snapshots) { s in
                                    Text("\(s.label) · \(s.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                        .tag(Optional(s.id))
                                }
                            }
                            .disabled(store.snapshots.isEmpty)
                            Button {
                                if let id = timerTargetSnapID {
                                    store.startExpiration(minutes: timerMinutes, restoreTo: id)
                                    flash("已启动 \(timerMinutes) 分钟定时")
                                }
                            } label: { Label("启动计时", systemImage: "play.fill") }
                            .buttonStyle(.borderedProminent)
                            .disabled(timerTargetSnapID == nil)
                        }
                    }
                }
            }
        }
    }

    private var presetsGrid: some View {
        let cols = [GridItem(.adaptive(minimum: 220), spacing: 10)]
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(PresetCatalog.all) { p in
                Button {
                    p.apply(store)
                    flash("已应用「\(p.title)」")
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Text(p.emoji).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.title).font(.body.bold())
                            Text(p.summary).font(.caption).foregroundColor(.secondary)
                                .lineLimit(2).multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
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
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func actionButton(icon: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
            flash(label + " 已执行")
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label).fontWeight(.medium)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(0.5), lineWidth: 1)
            )
            .foregroundColor(tint)
            .contentShape(Rectangle())
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

