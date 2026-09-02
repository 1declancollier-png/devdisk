import Foundation

let home = FileManager.default.homeDirectoryForCurrentUser.path

// (label, path, expectation) — controls are paths Apple gates behind Full Disk Access.
let targets: [(String, String, String)] = [
    ("DerivedData",        "\(home)/Library/Developer/Xcode/DerivedData",        "target"),
    ("CoreSimulator",      "\(home)/Library/Developer/CoreSimulator/Devices",    "target"),
    ("swiftpm cache",      "\(home)/Library/Caches/org.swift.swiftpm",           "target"),
    ("npm cacache",        "\(home)/.npm/_cacache",                              "target"),
    ("cargo cache",        "\(home)/.cargo/registry/cache",                      "target"),
    ("Library/Caches",     "\(home)/Library/Caches",                             "target"),
    ("Library/Developer",  "\(home)/Library/Developer",                          "target"),
    ("CONTROL TCC dir",    "\(home)/Library/Application Support/com.apple.TCC",  "control-fda"),
    ("CONTROL Safari",     "\(home)/Library/Safari",                             "control-fda"),
    ("CONTROL Containers", "\(home)/Library/Containers",                         "control-mixed"),
]

var out: [String] = []
let fm = FileManager.default

for (label, path, kind) in targets {
    guard fm.fileExists(atPath: path) else {
        out.append("ABSENT   [\(kind)] \(label) — \(path)")
        continue
    }
    do {
        let entries = try fm.contentsOfDirectory(atPath: path)
        // Listing can succeed where reading fails; try to actually touch one child.
        var readNote = "listed \(entries.count)"
        if let first = entries.first(where: { !$0.hasPrefix(".") }) {
            let child = (path as NSString).appendingPathComponent(first)
            var isDir: ObjCBool = false
            _ = fm.fileExists(atPath: child, isDirectory: &isDir)
            if isDir.boolValue {
                do { _ = try fm.contentsOfDirectory(atPath: child); readNote += ", descended ok" }
                catch { readNote += ", descend DENIED (\((error as NSError).code))" }
            } else {
                do { _ = try Data(contentsOf: URL(fileURLWithPath: child), options: .mappedIfSafe)
                     readNote += ", read child ok" }
                catch { readNote += ", read child DENIED (\((error as NSError).code))" }
            }
        }
        out.append("OK       [\(kind)] \(label) — \(readNote)")
    } catch {
        let ns = error as NSError
        out.append("DENIED   [\(kind)] \(label) — \(ns.domain) \(ns.code)")
    }
}

let dest = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/devdisk-phase0.txt"
let header = "context=\(ProcessInfo.processInfo.environment["DEVDISK_CTX"] ?? "unknown")  bundle=\(Bundle.main.bundleIdentifier ?? "none")"
try? ([header] + out).joined(separator: "\n").write(toFile: dest, atomically: true, encoding: .utf8)
