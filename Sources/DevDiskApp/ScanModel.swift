import Foundation
import Observation
import DevDiskCore

/// One scanner's results, collapsed for display.
struct ScanGroup: Identifiable, Sendable {
    let id: String
    let name: String
    let bytes: Int64
    let candidates: [Candidate]
    let needsSelection: Bool
}

@Observable
@MainActor
final class ScanModel {
    private(set) var groups: [ScanGroup] = []
    private(set) var total: Int64 = 0
    private(set) var isScanning = false
    private(set) var finishedAt: Date?
    private(set) var projectRoots: [URL] = []

    var hasResults: Bool { !groups.isEmpty }

    /// Runs on launch with no prompt of any kind — Phase 0 established that none of these
    /// locations needs a permission grant. Do not add one.
    func scanHomeCaches() async {
        isScanning = true
        defer { isScanning = false }

        let found = await Task.detached(priority: .userInitiated) { () -> [ScanGroup] in
            HomeCacheScanner.standardSet().compactMap { scanner in
                let sized = SizeCalculator.sized((try? scanner.enumerate()) ?? [])
                guard !sized.isEmpty else { return nil }
                return ScanGroup(
                    id: scanner.id,
                    name: scanner.displayName,
                    bytes: sized.reduce(0) { $0 + $1.sizeBytes },
                    candidates: sized.sorted { $0.sizeBytes > $1.sizeBytes },
                    needsSelection: false
                )
            }
        }.value

        merge(found)
        finishedAt = .now
    }

    /// The only path that involves the user picking anything. Selection *is* the grant —
    /// no TCC prompt is involved, even for ~/Documents or ~/Desktop.
    func scanProject(at root: URL) async {
        guard !projectRoots.contains(root) else { return }
        projectRoots.append(root)
        isScanning = true
        defer { isScanning = false }

        let found = await Task.detached(priority: .userInitiated) { () -> ScanGroup? in
            let sized = SizeCalculator.sized((try? ProjectTreeScanner(root: root).enumerate()) ?? [])
            guard !sized.isEmpty else { return nil }
            return ScanGroup(
                id: "project:\(root.path)",
                name: root.lastPathComponent,
                bytes: sized.reduce(0) { $0 + $1.sizeBytes },
                candidates: sized.sorted { $0.sizeBytes > $1.sizeBytes },
                needsSelection: true
            )
        }.value

        if let found { merge([found]) }
        finishedAt = .now
    }

    private func merge(_ incoming: [ScanGroup]) {
        for g in incoming where !groups.contains(where: { $0.id == g.id }) {
            groups.append(g)
        }
        groups.sort { $0.bytes > $1.bytes }
        total = groups.reduce(0) { $0 + $1.bytes }
    }
}
