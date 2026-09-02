import Foundation

/// What `docker system df` reports. Deliberately NOT a `Candidate`: Docker reclaim is not a
/// filesystem path, cannot be moved to the Trash, and therefore cannot be made recoverable.
/// It never goes through `Deleter`. See DECISIONS.md.
public struct DockerReport: Sendable, Equatable {
    public struct Line: Sendable, Equatable {
        public let type: String
        public let total: Int
        public let active: Int
        public let size: Int64
        public let reclaimable: Int64
    }
    public let lines: [Line]
    public var reclaimable: Int64 { lines.reduce(0) { $0 + $1.reclaimable } }

    /// The exact command the user would run. v1 shows this and does not execute it.
    public var pruneCommand: String { "docker system prune --all --volumes" }
}

public enum DockerProbe {
    /// A GUI app launched from Finder inherits a minimal PATH (/usr/bin:/bin:/usr/sbin:/sbin),
    /// so `docker` is almost never on it even when the user has Docker installed. Search the
    /// real install locations explicitly rather than trusting the environment.
    static let searchPaths: [String] = [
        "/usr/local/bin/docker",
        "/opt/homebrew/bin/docker",
        "/usr/bin/docker",
        "\(NSHomeDirectory())/.docker/bin/docker",
        "\(NSHomeDirectory())/.rd/bin/docker",          // Rancher Desktop
        "/Applications/Docker.app/Contents/Resources/bin/docker",
    ]

    public static func locate() -> URL? {
        let fm = FileManager.default
        for p in searchPaths where fm.isExecutableFile(atPath: p) {
            return URL(fileURLWithPath: p)
        }
        return nil
    }

    /// nil when Docker is not installed, or is installed but the daemon is not answering.
    /// Both are ordinary states, never an error the user should see.
    public static func report(timeout: TimeInterval = 4) -> DockerReport? {
        guard let docker = locate() else { return nil }
        guard let out = run(docker, ["system", "df", "--format", "{{json .}}"], timeout: timeout) else { return nil }

        var lines: [DockerReport.Line] = []
        for raw in out.split(separator: "\n") {
            guard let data = raw.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { continue }
            lines.append(.init(
                type: obj["Type"] as? String ?? "?",
                total: Int(obj["TotalCount"] as? String ?? "") ?? (obj["TotalCount"] as? Int ?? 0),
                active: Int(obj["Active"] as? String ?? "") ?? (obj["Active"] as? Int ?? 0),
                size: parseSize(obj["Size"] as? String ?? "0B"),
                reclaimable: parseSize(obj["Reclaimable"] as? String ?? "0B")
            ))
        }
        return lines.isEmpty ? nil : DockerReport(lines: lines)
    }

    /// Docker prints sizes like "1.093GB" or "512.4MB (100%)". Public so the size parsing —
    /// the only part of the Docker path that can be wrong on a machine without Docker — is
    /// covered by the self-test.
    public static func parseSize(_ s: String) -> Int64 {
        let trimmed = s.split(separator: " ").first.map(String.init) ?? s
        let units: [(String, Double)] = [
            ("TB", 1e12), ("GB", 1e9), ("MB", 1e6), ("kB", 1e3), ("KB", 1e3), ("B", 1),
        ]
        for (suffix, mult) in units where trimmed.hasSuffix(suffix) {
            let n = trimmed.dropLast(suffix.count)
            if let v = Double(n) { return Int64(v * mult) }
        }
        return 0
    }

    /// Runs a command with a hard timeout so a wedged daemon can never hang the UI.
    static func run(_ exe: URL, _ args: [String], timeout: TimeInterval) -> String? {
        let p = Process()
        p.executableURL = exe
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()
        guard (try? p.run()) != nil else { return nil }

        let deadline = Date().addingTimeInterval(timeout)
        while p.isRunning && Date() < deadline { usleep(50_000) }
        if p.isRunning { p.terminate(); return nil }
        guard p.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
