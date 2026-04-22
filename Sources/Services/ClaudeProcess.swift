import Foundation

/// Finds and terminates running `claude` CLI processes so the next `claude`
/// invocation picks up newly-written ~/.claude/settings.json.
enum ClaudeProcess {

    struct Info {
        let pid: Int32
        let command: String
    }

    /// Returns PIDs of processes whose name is (or starts with) `claude`.
    /// We filter strictly so we don't accidentally kill our own app
    /// (bundle name `ClaudeAccessManagement`) or other unrelated binaries.
    static func running() -> [Info] {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-axo", "pid=,comm="]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do { try task.run() } catch { return [] }
        task.waitUntilExit()

        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(),
                         encoding: .utf8) ?? ""
        let myPID = ProcessInfo.processInfo.processIdentifier
        var result: [Info] = []
        for line in out.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let space = trimmed.firstIndex(of: " ") else { continue }
            let pidPart = trimmed[..<space].trimmingCharacters(in: .whitespaces)
            let cmdPart = trimmed[trimmed.index(after: space)...]
                .trimmingCharacters(in: .whitespaces)
            guard let pid = Int32(pidPart), pid != myPID else { continue }
            // comm field is just the executable's basename. Match `claude`
            // and common variants (claude-code, node from ~/.claude/ etc.
            // would be captured by nameContains). Keep it strict.
            let last = (cmdPart as NSString).lastPathComponent
            guard last == "claude" || last.hasPrefix("claude-") else { continue }
            result.append(Info(pid: pid, command: cmdPart))
        }
        return result
    }

    /// Sends SIGTERM to all detected claude processes. Returns killed PIDs.
    @discardableResult
    static func terminateAll() -> [Int32] {
        let procs = running()
        var killed: [Int32] = []
        for p in procs {
            if kill(p.pid, SIGTERM) == 0 {
                killed.append(p.pid)
            }
        }
        return killed
    }
}
