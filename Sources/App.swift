import SwiftUI

@main
struct ClaudeAccessManagementApp: App {
    @StateObject private var store = PermissionStore()

    var body: some Scene {
        WindowGroup("Claude Access Manager") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1100, idealWidth: 1280,
                       minHeight: 720, idealHeight: 820)
                .onAppear {
                    store.load()
                    // Set the initial window size explicitly on macOS 12
                    // (defaultSize() is macOS 13+). This runs once per launch.
                    if let w = NSApp.windows.first {
                        let size = NSSize(width: 1280, height: 820)
                        w.setContentSize(size)
                        w.center()
                    }
                }
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
