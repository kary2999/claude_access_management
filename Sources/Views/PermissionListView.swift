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
        VStack(alignment: .leading, spacing: 0) {
            toolbar
            Divider()
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(rows) { row in
                        ruleRow(row)
                    }
                }
                .padding(.horizontal, 68)
                .padding(.vertical, 20)
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("搜索指令或用途…", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.1))
            )
            .frame(maxWidth: 320)

            Chip("全部", active: filter == nil) { filter = nil }
            ForEach(RiskLevel.allCases) { l in
                Chip(l.label, active: filter == l, color: l.color) {
                    filter = (filter == l) ? nil : l
                }
            }
            Spacer()
            Text("\(rows.count) 条").font(.caption).foregroundColor(.secondary)
        }
        .padding(.horizontal, 68)
        .padding(.vertical, 14)
    }

    private func ruleRow(_ row: CommandEntry) -> some View {
        let current = store.state(of: row.rule)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(row.rule).font(.system(.body, design: .monospaced)).bold()
                    RiskBadge(level: row.risk)
                }
                Text(row.purpose).font(.caption).foregroundColor(.secondary)
                Text(row.danger).font(.caption2).foregroundColor(.secondary)
                    .padding(.top, 1)
            }
            Spacer()
            HStack(spacing: 4) {
                stateChip("Allow", bucket: .allow, rule: row.rule, current: current, tint: .green)
                stateChip("Ask",   bucket: .ask,   rule: row.rule, current: current, tint: .yellow)
                stateChip("Deny",  bucket: .deny,  rule: row.rule, current: current, tint: .red)
                Button {
                    store.set(row.rule, to: nil)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("清除此条授权（恢复默认询问）")
                .opacity(current == nil ? 0.25 : 1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.cardBG)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.subtleBorder, lineWidth: 1)
        )
    }

    private func stateChip(_ title: String,
                           bucket: PermissionStore.Bucket,
                           rule: String,
                           current: PermissionStore.Bucket?,
                           tint: Color) -> some View {
        let active = (current == bucket)
        return Button {
            store.set(rule, to: active ? nil : bucket)
        } label: {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(active ? tint.opacity(0.25) : Color.secondary.opacity(0.08))
                )
                .foregroundColor(active ? tint : .secondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
