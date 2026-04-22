import SwiftUI
import AppKit

struct DirectoryListView: View {
    @EnvironmentObject var store: PermissionStore

    var dirs: [String] { store.settings.permissions?.additionalDirectories ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(
                    title: "目录白名单",
                    subtitle: "Claude 默认只能访问当前工作目录，这里加入的目录会被额外授权")
                Spacer()
                Button {
                    pickDirectory()
                } label: {
                    Label("添加目录", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            if dirs.isEmpty {
                Card {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield")
                            .font(.title).foregroundColor(.secondary)
                        VStack(alignment: .leading) {
                            Text("未授权任何额外目录").font(.body.bold())
                            Text("Claude 只能读写当前工作目录的文件。")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            } else {
                Card {
                    VStack(spacing: 6) {
                        ForEach(dirs, id: \.self) { d in
                            HStack(spacing: 10) {
                                Image(systemName: "folder.fill").foregroundColor(.accentColor)
                                Text(d).font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .lineLimit(1).truncationMode(.middle)
                                Spacer()
                                Button {
                                    NSWorkspace.shared.selectFile(d, inFileViewerRootedAtPath: "")
                                } label: { Image(systemName: "arrow.up.forward.app") }
                                    .buttonStyle(.plain).help("在 Finder 中打开")
                                Button {
                                    store.removeDirectory(d)
                                } label: { Image(systemName: "trash") }
                                    .buttonStyle(.plain).foregroundColor(.red)
                                    .help("移除")
                            }
                            .padding(.vertical, 4)
                            if d != dirs.last { Divider().opacity(0.4) }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 68)
        .padding(.vertical, 36)
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
