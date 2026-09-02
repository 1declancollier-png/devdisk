import Foundation
import DevDiskCore

// Report-only by construction. This binary contains no call to Deleter — deletion lives in the
// app, where every path is on screen and ticked individually before anything moves.

let version = "0.1.0"
var args = Array(CommandLine.arguments.dropFirst())
var asJSON = false
var roots: [URL] = []

func usage() -> Never {
    print("""
    devdisk \(version) — find developer build caches eating your disk

    USAGE
      devdisk [options] [project-folder ...]

    OPTIONS
      --json        machine-readable output
      --version     print version
      --help        this

    devdisk only reports. It cannot delete anything.
    Every path it can ever propose is listed in MANIFEST.md, generated from the source.
    """)
    exit(0)
}

while let a = args.first {
    args.removeFirst()
    switch a {
    case "--json": asJSON = true
    case "--version": print(version); exit(0)
    case "--help", "-h": usage()
    default:
        guard !a.hasPrefix("-") else {
            FileHandle.standardError.write("unknown option: \(a)\n".data(using: .utf8)!)
            exit(2)
        }
        roots.append(URL(fileURLWithPath: a))
    }
}

struct Section { let name: String; let bytes: Int64; let items: [Candidate] }
var sections: [Section] = []

for scanner in HomeCacheScanner.standardSet() {
    let sized = SizeCalculator.sized((try? scanner.enumerate()) ?? [])
    guard !sized.isEmpty else { continue }
    sections.append(Section(name: scanner.displayName,
                            bytes: sized.reduce(0) { $0 + $1.sizeBytes },
                            items: sized))
}
for root in roots {
    let sized = SizeCalculator.sized((try? ProjectTreeScanner(root: root).enumerate()) ?? [])
    guard !sized.isEmpty else { continue }
    sections.append(Section(name: "\(root.lastPathComponent) (project artifacts)",
                            bytes: sized.reduce(0) { $0 + $1.sizeBytes },
                            items: sized))
}
sections.sort { $0.bytes > $1.bytes }
let grand = sections.reduce(0) { $0 + $1.bytes }

if asJSON {
    let payload: [String: Any] = [
        "version": version,
        "reclaimableBytes": grand,
        "sections": sections.map { s in
            [
                "name": s.name,
                "bytes": s.bytes,
                "paths": s.items.map { ["path": $0.url.path, "bytes": $0.sizeBytes] },
            ] as [String: Any]
        },
    ]
    let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    print(String(data: data, encoding: .utf8)!)
    exit(0)
}

if let docker = DockerProbe.report() {
    sections.append(Section(name: "Docker (reported only)", bytes: docker.reclaimable, items: []))
}

print("")
print("  \(SizeCalculator.human(grand)) reclaimable")
print("")
for s in sections {
    let size = SizeCalculator.human(s.bytes).padding(toLength: 10, withPad: " ", startingAt: 0)
    print("  \(size)  \(s.name)  (\(s.items.count) item\(s.items.count == 1 ? "" : "s"))")
}
if roots.isEmpty {
    print("")
    print("  Pass a folder to also scan for node_modules, target/, .venv and friends:")
    print("    devdisk ~/Developer")
}
print("")
print("  Nothing was deleted. This tool cannot delete.")
print("")
