import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: PermissionStore
    @State private var tab: Tab = .commands

    enum Tab: String, CaseIterable, Identifiable {
        case commands = "指令授权"
        case directories = "目录白名单"
        case snapshots = "快照与定时"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationSplitView {
            List(Tab.allCases, selection: $tab) { t in
                NavigationLink(value: t) {
                    Label(t.rawValue, systemImage: icon(for: t))
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .listStyle(.sidebar)

            VStack(alignment: .leading, spacing: 4) {
                Divider()
                Text("版本 \(AppVersion.full)")
                    .font(.caption).foregroundColor(.secondary)
                    .padding(.horizontal).padding(.bottom, 8)
            }
        } detail: {
            Group {
                switch tab {
                case .commands: PermissionListView()
                case .directories: DirectoryListView()
                case .snapshots: SnapshotView()
                }
            }
            .navigationTitle(tab.rawValue)
        }
        .alert("出错了", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } })
        ) {
            Button("好") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }

    private func icon(for t: Tab) -> String {
        switch t {
        case .commands: return "terminal"
        case .directories: return "folder.badge.gearshape"
        case .snapshots: return "clock.arrow.circlepath"
        }
    }
}
