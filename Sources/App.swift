import SwiftUI

@main
struct ClaudeAccessManagementApp: App {
    @StateObject private var store = PermissionStore()

    var body: some Scene {
        WindowGroup("Claude Access Manager") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear { store.load() }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Claude Access Manager") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationVersion: AppVersion.full,
                        .version: AppVersion.build
                    ])
                }
            }
        }
    }
}

enum AppVersion {
    static let marketing = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static var full: String { "\(marketing) (\(build))" }
}
