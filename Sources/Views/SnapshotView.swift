import SwiftUI

struct SnapshotView: View {
    @EnvironmentObject var store: PermissionStore
    @State private var label: String = ""
    @State private var minutes: Int = 30
    @State private var selectedSnapID: UUID? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "快照与定时",
                              subtitle: "保存当前授权配置，或让它过期自动回滚")

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
                        Text("定时授权").font(.headline)
                        Text("到期后自动恢复到指定快照，避免授权长期泄露。")
                            .font(.caption).foregroundColor(.secondary)
                        HStack {
                            Stepper("有效时间：\(minutes) 分钟", value: $minutes, in: 1...1440, step: 5)
                            Spacer()
                        }
                        HStack(spacing: 10) {
                            Picker("到期恢复到", selection: $selectedSnapID) {
                                Text("选择快照…").tag(UUID?.none)
                                ForEach(store.snapshots) { s in
                                    Text("\(s.label) · \(s.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                        .tag(Optional(s.id))
                                }
                            }
                            Button {
                                if let id = selectedSnapID {
                                    store.startExpiration(minutes: minutes, restoreTo: id)
                                }
                            } label: { Label("启动计时", systemImage: "play.fill") }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedSnapID == nil)
                        }
                        if let t = store.expiresAt {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                                Text("将于 \(t.formatted(date: .abbreviated, time: .standard)) 自动恢复")
                                    .font(.callout)
                                Spacer()
                                Button("取消") { store.cancelExpiration() }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.12))
                            )
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
            .padding(20)
        }
    }
}
