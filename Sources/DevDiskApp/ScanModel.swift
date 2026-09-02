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

    /// Keyed by path. Nothing is ever selected by default — the user ticks each item.
    /// Candidates are top-level children of a cache, so real counts are small (single digits),
    /// which is what makes per-item selection reasonable rather than hostile.
    private(set) var selected: Set<String> = []
    private(set) var lastError: String?

    /// nil whenever Docker is absent or its daemon is not answering. Both are ordinary states:
    /// the section simply does not appear. Never surfaced as an error.
    private(set) var docker: DockerReport?

    private let rootStore = ProjectRoots()

    var hasResults: Bool { !groups.isEmpty }

    // MARK: selection

    func isSelected(_ c: Candidate) -> Bool { selected.contains(c.url.path) }

    func toggle(_ c: Candidate) {
        if selected.contains(c.url.path) { selected.remove(c.url.path) }
        else { selected.insert(c.url.path) }
    }

    var selectedCandidates: [Candidate] {
        groups.flatMap(\.candidates).filter { selected.contains($0.url.path) }
    }
    var selectedCount: Int { selectedCandidates.count }
    var selectedBytes: Int64 { selectedCandidates.reduce(0) { $0 + $1.sizeBytes } }

    // MARK: deletion

    /// Moves exactly the ticked items to the Trash. `Deleter` validates every candidate against
    /// SafetyGuard before removing any of them, so an unsafe selection removes nothing at all.
    func deleteSelected() async {
        let batch = selectedCandidates
        guard !batch.isEmpty else { return }
        lastError = nil
        do {
            try Deleter().delete(batch)
            selected.removeAll()
            groups.removeAll()
            total = 0
            await scanHomeCaches()
            let roots = projectRoots
            projectRoots.removeAll()
            for r in roots { await scanProject(at: r, remember: false) }
            docker = await Task.detached(priority: .utility) { DockerProbe.report() }.value
        } catch {
            lastError = "\(error)"
        }
    }

    /// Everything the app does on launch: caches, remembered project folders, Docker probe.
    /// No prompt of any kind.
    func startup() async {
        await scanHomeCaches()
        for root in rootStore.load() { await scanProject(at: root, remember: false) }
        docker = await Task.detached(priority: .utility) { DockerProbe.report() }.value
    }

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
    func scanProject(at root: URL, remember: Bool = true) async {
        guard !projectRoots.contains(root) else { return }
        projectRoots.append(root)
        if remember { rootStore.add(root) }
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

    func forgetProject(_ root: URL) {
        rootStore.remove(root)
        projectRoots.removeAll { $0 == root }
        groups.removeAll { $0.id == "project:\(root.path)" }
        total = groups.reduce(0) { $0 + $1.bytes }
    }

    private func merge(_ incoming: [ScanGroup]) {
        for g in incoming where !groups.contains(where: { $0.id == g.id }) {
            groups.append(g)
        }
        groups.sort { $0.bytes > $1.bytes }
        total = groups.reduce(0) { $0 + $1.bytes }
    }
}
