import SwiftUI

struct PermissionListView: View {
    @EnvironmentObject var store: PermissionStore
    @State private var filter: RiskLevel? = nil
    @State private var search: String = ""

    var rows: [CommandEntry] {
        CommandCatalog.all.filter {
            (filter == nil || $0.risk == filter) &&
            (search.isEmpty || $0.rule.localizedCaseInsensitiveContains(search) || $0.purpose.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("搜索指令…", text: $search)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                Picker("风险", selection: $filter) {
                    Text("全部").tag(Optional<RiskLevel>.none)
                    ForEach(RiskLevel.allCases) { l in
                        Text(l.label).tag(Optional(l))
                    }
                }.pickerStyle(.menu).frame(maxWidth: 160)
                Spacer()
            }

            Table(rows) {
                TableColumn("指令") { row in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.rule).font(.system(.body, design: .monospaced))
                        Text(row.purpose).font(.caption).foregroundColor(.secondary)
                    }
                }
                TableColumn("风险") { row in RiskBadge(level: row.risk) }.width(100)
                TableColumn("说明") { row in
                    Text(row.danger).font(.caption).foregroundColor(.secondary)
                }
                TableColumn("状态") { row in
                    Picker("", selection: Binding(
                        get: { store.state(of: row.rule) },
                        set: { store.set(row.rule, to: $0) }
                    )) {
                        Text("—").tag(PermissionStore.Bucket?.none)
                        Text("Allow").tag(Optional(PermissionStore.Bucket.allow))
                        Text("Ask").tag(Optional(PermissionStore.Bucket.ask))
                        Text("Deny").tag(Optional(PermissionStore.Bucket.deny))
                    }.labelsHidden().frame(width: 120)
                }.width(140)
            }
        }
        .padding()
    }
}
