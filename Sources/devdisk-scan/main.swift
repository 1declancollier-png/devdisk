import Foundation
import DevDiskCore

// Dry run only. This executable has no delete path at all — by construction, not by a flag.
var report: [(String, Int64, Int)] = []
var grand: Int64 = 0

for scanner in HomeCacheScanner.standardSet() {
    let sized = SizeCalculator.sized((try? scanner.enumerate()) ?? [])
    guard !sized.isEmpty else { continue }
    let total = sized.reduce(0) { $0 + $1.sizeBytes }
    report.append((scanner.displayName, total, sized.count))
    grand += total
}

let roots = CommandLine.arguments.dropFirst().map { URL(fileURLWithPath: $0) }
for root in roots {
    let sized = SizeCalculator.sized((try? ProjectTreeScanner(root: root).enumerate()) ?? [])
    guard !sized.isEmpty else { continue }
    let total = sized.reduce(0) { $0 + $1.sizeBytes }
    report.append(("\(root.lastPathComponent) (project artifacts)", total, sized.count))
    grand += total
}

print("")
print("  \(SizeCalculator.human(grand)) reclaimable")
print("")
for (name, bytes, count) in report.sorted(by: { $0.1 > $1.1 }) {
    let size = SizeCalculator.human(bytes).padding(toLength: 10, withPad: " ", startingAt: 0)
    print("  \(size)  \(name)  (\(count) item\(count == 1 ? "" : "s"))")
}
print("")
print("  Nothing was deleted. Nothing was selected. This tool cannot delete.")
print("")
