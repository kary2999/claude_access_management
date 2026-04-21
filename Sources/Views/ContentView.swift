import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: PermissionStore
    @State private var tab: Tab = .commands

    enum Tab: String, CaseIterable, Identifiable, Hashable {
        case commands = "指令授权"
        case directories = "目录白名单"
        case snapshots = "快照与定时"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .commands: return "terminal"
            case .directories: return "folder.badge.gearshape"
            case .snapshots: return "clock.arrow.circlepath"
            }
        }
    }

    var body: some View {
        NavigationView {
            sidebar
            detailView
                .frame(minWidth: 640, minHeight: 500)
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
            List {
                ForEach(Tab.allCases) { t in
                    Button {
                        tab = t
                    } label: {
                        Label(t.rawValue, systemImage: t.icon)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .listRowBackground(tab == t ? Color.accentColor.opacity(0.15) : Color.clear)
                }
            }
            .listStyle(.sidebar)

            Divider()
            Text("版本 \(AppVersion.full)")
                .font(.caption).foregroundColor(.secondary)
                .padding(10)
        }
        .frame(minWidth: 200)
    }

    @ViewBuilder
    private var detailView: some View {
        switch tab {
        case .commands: PermissionListView()
        case .directories: DirectoryListView()
        case .snapshots: SnapshotView()
        }
    }
}
