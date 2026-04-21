import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: PermissionStore
    @State private var tab: Tab = .dashboard

    enum Tab: String, CaseIterable, Identifiable, Hashable {
        case dashboard   = "概览"
        case commands    = "指令授权"
        case directories = "目录白名单"
        case snapshots   = "快照与定时"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .dashboard:   return "square.grid.2x2"
            case .commands:    return "terminal"
            case .directories: return "folder.badge.gearshape"
            case .snapshots:   return "clock.arrow.circlepath"
            }
        }
        var subtitle: String {
            switch self {
            case .dashboard:   return "权限概览 + 快速操作"
            case .commands:    return "逐条控制 Allow / Ask / Deny"
            case .directories: return "Claude 可访问的目录白名单"
            case .snapshots:   return "保存 / 恢复 / 定时自动恢复"
            }
        }
    }

    var body: some View {
        NavigationView {
            sidebar
            detailView
                .frame(minWidth: 720, minHeight: 560)
        }
        .alert(isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } })
        ) {
            Alert(title: Text("出错了"),
                  message: Text(store.errorMessage ?? ""),
                  dismissButton: .default(Text("好")))
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Brand header with breathing room
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text("🍯").font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Claude Access").font(.headline)
                        Text("Manager").font(.headline)
                    }
                    Spacer(minLength: 0)
                }
                Text("v\(AppVersion.marketing)")
                    .font(.caption2).foregroundColor(.secondary)
                    .padding(.leading, 38)
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider().padding(.horizontal, 12)

            // Tabs with outer horizontal margin so they don't touch edges
            VStack(spacing: 6) {
                ForEach(Tab.allCases) { t in
                    sidebarButton(t)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Spacer()

            // Footer
            HStack(spacing: 6) {
                Image(systemName: "externaldrive")
                    .foregroundColor(.secondary).font(.caption)
                Text("~/.claude/settings.json")
                    .font(.caption2).foregroundColor(.secondary)
                    .lineLimit(1).truncationMode(.middle)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(minWidth: 240, idealWidth: 260, maxWidth: 280)
        .background(Theme.cardBG)
    }

    private func sidebarButton(_ t: Tab) -> some View {
        let active = tab == t
        return Button {
            tab = t
        } label: {
            HStack(spacing: 12) {
                Image(systemName: t.icon)
                    .frame(width: 22, height: 22)
                    .foregroundColor(active ? .white : .accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.rawValue).font(.body)
                        .foregroundColor(active ? .white : .primary)
                    Text(t.subtitle).font(.caption2)
                        .foregroundColor(active ? .white.opacity(0.85) : .secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(active ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var detailView: some View {
        switch tab {
        case .dashboard:   DashboardView()
        case .commands:    PermissionListView()
        case .directories: DirectoryListView()
        case .snapshots:   SnapshotView()
        }
    }
}
