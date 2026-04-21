import SwiftUI
import AppKit

struct DirectoryListView: View {
    @EnvironmentObject var store: PermissionStore

    var dirs: [String] { store.settings.permissions?.additionalDirectories ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("授权目录").font(.headline)
                Spacer()
                Button("添加目录…") { pickDirectory() }
            }
            if dirs.isEmpty {
                Text("尚未授权任何额外目录。Claude 默认只能读取当前工作目录。")
                    .foregroundColor(.secondary).font(.callout)
            }
            List {
                ForEach(dirs, id: \.self) { d in
                    HStack {
                        Image(systemName: "folder")
                        Text(d).font(.system(.body, design: .monospaced))
                        Spacer()
                        Button(role: .destructive) {
                            store.removeDirectory(d)
                        } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }.padding()
    }

    private func pickDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "授权"
        if panel.runModal() == .OK, let url = panel.url {
            store.addDirectory(url.path)
        }
    }
}
