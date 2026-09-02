import Foundation

/// Every reason the guard will refuse a candidate. One case per invariant in SPEC.md §5.
public enum SafetyViolation: Error, Equatable, CustomStringConvertible {
    case notDescendantOfRoot(path: String, root: String)
    case isRootItself(path: String)
    case escapesRootViaSymlink(path: String, resolvedTo: String)
    case containsGitRepository(path: String)
    case missingMarkerFile(path: String, expected: [String])
    case markerNotASibling(path: String, marker: String)

    public var description: String {
        switch self {
        case let .notDescendantOfRoot(p, r):   "\(p) is not inside the scanned root \(r)"
        case let .isRootItself(p):             "\(p) is the scanned root itself, not something inside it"
        case let .escapesRootViaSymlink(p, t): "\(p) is a symlink escaping the root (resolves to \(t))"
        case let .containsGitRepository(p):    "\(p) contains a .git directory — that is a repository, not a build artifact"
        case let .missingMarkerFile(p, e):     "\(p) matched by name only; none of \(e.joined(separator: ", ")) is present alongside it"
        case let .markerNotASibling(p, m):     "marker \(m) is not a sibling of \(p)"
        }
    }
}

public enum SafetyGuard {
    /// Lexical normalisation only — no symlink resolution. Used for the "did the scanner even
    /// claim this was inside the root" check, which must not be satisfiable by a symlink.
    static func lexical(_ url: URL) -> URL {
        URL(fileURLWithPath: url.path).standardizedFileURL
    }

    /// Full resolution, including symlinks. Used to catch a path that *looks* contained but is not.
    static func canonical(_ url: URL) -> URL {
        URL(fileURLWithPath: url.path).standardizedFileURL.resolvingSymlinksInPath()
    }

    static func isStrictDescendant(_ url: URL, of root: URL) -> Bool {
        let u = url.pathComponents, r = root.pathComponents
        guard u.count > r.count else { return false }
        return Array(u.prefix(r.count)) == r
    }

    /// Throws on the first invariant a candidate violates. A candidate that survives this is
    /// safe to hand to `Deleter` — nothing else in the codebase may delete.
    public static func validate(_ c: Candidate, fileManager fm: FileManager = .default) throws {
        let lexPath = lexical(c.url)
        let lexRoot = lexical(c.root)

        // 1. Confined to the root, and never the root itself.
        if lexPath == lexRoot {
            throw SafetyViolation.isRootItself(path: lexPath.path)
        }
        guard isStrictDescendant(lexPath, of: lexRoot) else {
            throw SafetyViolation.notDescendantOfRoot(path: lexPath.path, root: lexRoot.path)
        }

        // 2. Still confined once symlinks are resolved.
        let canPath = canonical(c.url)
        let canRoot = canonical(c.root)
        guard isStrictDescendant(canPath, of: canRoot) else {
            throw SafetyViolation.escapesRootViaSymlink(path: lexPath.path, resolvedTo: canPath.path)
        }

        // 3. Never a repository.
        var isDir: ObjCBool = false
        let gitPath = lexPath.appendingPathComponent(".git").path
        if fm.fileExists(atPath: gitPath, isDirectory: &isDir) {
            throw SafetyViolation.containsGitRepository(path: lexPath.path)
        }

        // 4. Project artifacts need a sibling marker; a matching directory name is never enough.
        if c.kind == .projectArtifact {
            guard let marker = c.justification else {
                throw SafetyViolation.missingMarkerFile(
                    path: lexPath.path,
                    expected: ProjectRule.markers(forDirectoryNamed: lexPath.lastPathComponent)
                )
            }
            let lexMarker = lexical(marker)
            guard lexMarker.deletingLastPathComponent() == lexPath.deletingLastPathComponent() else {
                throw SafetyViolation.markerNotASibling(path: lexPath.path, marker: lexMarker.path)
            }
            guard fm.fileExists(atPath: lexMarker.path) else {
                throw SafetyViolation.missingMarkerFile(path: lexPath.path, expected: [lexMarker.lastPathComponent])
            }
        }
    }
}
