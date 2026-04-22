import SwiftUI

struct SnapshotView: View {
    @EnvironmentObject var store: PermissionStore
    @State private var label: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "快照管理",
                              subtitle: "保存当前授权配置，随时可恢复。定时恢复入口在「概览」页。")

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("保存当前为快照").font(.headline)
                        HStack {
                            TextField("标签（如：默认保守配置）", text: $label)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                let l = label.isEmpty ? "snapshot-\(Date().ISO8601Format())" : label
                                store.snapshot(label: l)
                                label = ""
                            } label: {
                                Label("保存", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("已有快照").font(.headline)
                            Spacer()
                            Text("\(store.snapshots.count) 个").font(.caption).foregroundColor(.secondary)
                        }
                        if store.snapshots.isEmpty {
                            Text("还没有快照。保存一个后即可用于定时恢复或一键还原。")
                                .font(.caption).foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(store.snapshots) { s in
                                    HStack {
                                        Image(systemName: "camera.aperture").foregroundColor(.accentColor)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(s.label).font(.body.bold())
                                            Text(s.createdAt.formatted(date: .abbreviated, time: .standard))
                                                .font(.caption2).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button("恢复") { store.restore(s) }
                                            .buttonStyle(.bordered)
                                        Button {
                                            store.deleteSnapshot(s)
                                        } label: { Image(systemName: "trash") }
                                            .buttonStyle(.plain).foregroundColor(.red)
                                    }
                                    .padding(.vertical, 6)
                                    if s.id != store.snapshots.last?.id { Divider().opacity(0.4) }
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 38)
            .padding(.vertical, 28)
        }
    }
}
