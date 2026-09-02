import Foundation

/// The only thing in the codebase permitted to remove a candidate. Every call validates first.
public struct Deleter {
    /// Injectable so tests can assert the guard runs *before* anything is touched, without
    /// actually moving files. Production always uses `TrashRemover`.
    public protocol Remover: Sendable {
        func remove(_ url: URL) throws
    }

    /// Moves to Trash. v1 never unlinks — the user can always undo from Finder.
    public struct TrashRemover: Remover {
        public init() {}
        public func remove(_ url: URL) throws {
            var resulting: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &resulting)
        }
    }

    private let remover: Remover
    private let fm: FileManager

    public init(remover: Remover = TrashRemover(), fileManager: FileManager = .default) {
        self.remover = remover
        self.fm = fileManager
    }

    /// Validates, then trashes. A violation throws and removes nothing.
    public func delete(_ candidate: Candidate) throws {
        try SafetyGuard.validate(candidate, fileManager: fm)
        try remover.remove(candidate.url)
    }

    /// Validates every candidate before removing any. One bad candidate aborts the whole batch,
    /// so a partially-trusted selection never half-executes.
    public func delete(_ candidates: [Candidate]) throws {
        for c in candidates { try SafetyGuard.validate(c, fileManager: fm) }
        for c in candidates { try remover.remove(c.url) }
    }
}
