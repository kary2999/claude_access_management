import SwiftUI

struct SnapshotView: View {
    @EnvironmentObject var store: PermissionStore
    @State private var label: String = ""
    @State private var minutes: Int = 30
    @State private var selectedSnapID: UUID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("快照") {
                HStack {
                    TextField("标签（如：默认保守配置）", text: $label)
                        .textFieldStyle(.roundedBorder)
                    Button("保存当前为快照") {
                        let l = label.isEmpty ? "snapshot-\(Date().ISO8601Format())" : label
                        store.snapshot(label: l)
                        label = ""
                    }
                }.padding(8)
            }

            GroupBox("定时授权（到期恢复快照）") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Stepper("有效时间：\(minutes) 分钟", value: $minutes, in: 1...1440, step: 5)
                        Spacer()
                    }
                    HStack {
                        Picker("到期恢复到", selection: $selectedSnapID) {
                            Text("选择快照…").tag(UUID?.none)
                            ForEach(store.snapshots) { s in
                                Text("\(s.label) · \(s.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                    .tag(Optional(s.id))
                            }
                        }
                        Button("启动计时") {
                            if let id = selectedSnapID {
                                store.startExpiration(minutes: minutes, restoreTo: id)
                            }
                        }.disabled(selectedSnapID == nil)
                    }
                    if let t = store.expiresAt {
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark").foregroundColor(.orange)
                            Text("将于 \(t.formatted(date: .abbreviated, time: .standard)) 自动恢复")
                            Spacer()
                            Button("取消") { store.cancelExpiration() }
                        }
                    }
                }.padding(8)
            }

            GroupBox("已有快照") {
                List {
                    ForEach(store.snapshots) { s in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(s.label).font(.body.bold())
                                Text(s.createdAt.formatted(date: .abbreviated, time: .standard))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("恢复") { store.restore(s) }
                            Button(role: .destructive) { store.deleteSnapshot(s) } label: {
                                Image(systemName: "trash")
                            }.buttonStyle(.borderless)
                        }
                    }
                }.frame(minHeight: 180)
            }
            Spacer()
        }.padding()
    }
}
