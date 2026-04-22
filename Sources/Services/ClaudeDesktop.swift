import Foundation
import AppKit

/// Detects whether the Claude Desktop (Electron) app is installed, and
/// exposes helpers to open it. Needed because Claude Desktop has its own
/// UI permission-mode selector that overrides ~/.claude/settings.json —
/// YOLO via this manager only applies to direct CLI launches, so we
/// instruct the user accordingly when Desktop is present.
enum ClaudeDesktop {

    /// Common install locations. `/Applications` is standard;
    /// `~/Applications` is the per-user install variant.
    static let candidatePaths: [String] = [
        "/Applications/Claude.app",
        NSString(string: "~/Applications/Claude.app").expandingTildeInPath
    ]

    static var installedPath: String? {
        candidatePaths.first { FileManager.default.fileExists(atPath: $0) }
    }

    static var isInstalled: Bool { installedPath != nil }

    /// Parses CFBundleShortVersionString from the installed app's Info.plist.
    static var version: String? {
        guard let path = installedPath else { return nil }
        let info = "\(path)/Contents/Info.plist"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: info)),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data, format: nil) as? [String: Any] else { return nil }
        return plist["CFBundleShortVersionString"] as? String
    }

    static var isRunning: Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == "com.anthropic.claudefordesktop" ||
            (app.bundleURL?.lastPathComponent == "Claude.app")
        }
    }

    /// Brings Claude Desktop to the foreground (launches it if not running).
    static func activate() {
        guard let path = installedPath else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    /// Activates the app and then tries to send Cmd+, to open its
    /// Settings window. Best-effort — if the app hasn't finished
    /// launching this will no-op, the user can still press Cmd+,
    /// themselves once it's in front.
    static func activateAndOpenSettings() {
        activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let script = """
            tell application "System Events"
              tell process "Claude" to keystroke "," using command down
            end tell
            """
            var err: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&err)
        }
    }

    static func revealInFinder() {
        guard let path = installedPath else { return }
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}
