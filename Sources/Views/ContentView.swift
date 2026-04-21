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
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("🍯").font(.title)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Claude Access").font(.headline)
                        Text("Manager").font(.headline)
                    }
                }
                Text("v\(AppVersion.marketing)")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)

            Divider()

            VStack(spacing: 4) {
                ForEach(Tab.allCases) { t in
                    sidebarButton(t)
                }
            }
            .padding(8)

            Spacer()

            HStack {
                Image(systemName: "externaldrive")
                    .foregroundColor(.secondary)
                Text("~/.claude/settings.json")
                    .font(.caption2).foregroundColor(.secondary).lineLimit(1)
            }
            .padding(10)
        }
        .frame(minWidth: 220, idealWidth: 240, maxWidth: 260)
        .background(Theme.cardBG)
    }

    private func sidebarButton(_ t: Tab) -> some View {
        let active = tab == t
        return Button {
            tab = t
        } label: {
            HStack(spacing: 10) {
                Image(systemName: t.icon)
                    .frame(width: 20)
                    .foregroundColor(active ? .white : .accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(t.rawValue).font(.body)
                        .foregroundColor(active ? .white : .primary)
                    Text(t.subtitle).font(.caption2)
                        .foregroundColor(active ? .white.opacity(0.8) : .secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(active ? Color.accentColor : Color.clear)
            )
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
