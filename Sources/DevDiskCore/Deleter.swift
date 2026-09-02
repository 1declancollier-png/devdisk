import Foundation

/// The only thing in the codebase permitted to remove a candidate. Every call validates first.
public struct Deleter {
    /// Injectable so tests can assert the guard runs *before* anything is touched, without
    /// actually moving files. Production always uses `TrashRemover`.
    public protocol Remover: Sendable {
        /// Returns where the item ended up, so callers can prove it is recoverable.
        @discardableResult
        func remove(_ url: URL) throws -> URL?
    }

    /// Moves to Trash. v1 never unlinks — the user can always undo from Finder.
    public struct TrashRemover: Remover {
        public init() {}
        @discardableResult
        public func remove(_ url: URL) throws -> URL? {
            var resulting: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &resulting)
            return resulting as URL?
        }
    }

    private let remover: Remover
    private let fm: FileManager

    public init(remover: Remover = TrashRemover(), fileManager: FileManager = .default) {
        self.remover = remover
        self.fm = fileManager
    }

    /// Validates, then trashes. A violation throws and removes nothing.
    /// Returns where the item landed in the Trash, when the remover reports it.
    @discardableResult
    public func delete(_ candidate: Candidate) throws -> URL? {
        try SafetyGuard.validate(candidate, fileManager: fm)
        return try remover.remove(candidate.url)
    }

    /// Validates every candidate before removing any. One bad candidate aborts the whole batch,
    /// so a partially-trusted selection never half-executes.
    @discardableResult
    public func delete(_ candidates: [Candidate]) throws -> [URL] {
        for c in candidates { try SafetyGuard.validate(c, fileManager: fm) }
        var landed: [URL] = []
        for c in candidates { if let u = try remover.remove(c.url) { landed.append(u) } }
        return landed
    }
}
