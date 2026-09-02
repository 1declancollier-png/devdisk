import Foundation

public protocol Scanner: Sendable {
    var id: String { get }
    var displayName: String { get }
    /// Phase 0 established that no scanner needs Full Disk Access. Project scanners still need
    /// the user to pick a folder, which is a selection, not a permission grant.
    var requiresFolderSelection: Bool { get }
    func enumerate() throws -> [Candidate]
}

/// Scans a well-known cache directory under the user's home. Emits the directory's *children*,
/// never the directory itself, so the cache root always survives.
public struct HomeCacheScanner: Scanner {
    public let id: String
    public let displayName: String
    public let root: URL
    public var requiresFolderSelection: Bool { false }

    public init(id: String, displayName: String, root: URL) {
        self.id = id
        self.displayName = displayName
        self.root = root
    }

    public func enumerate() throws -> [Candidate] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: root.path) else { return [] }
        let children = try fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isSymbolicLinkKey],
            options: []
        )
        return children.map {
            Candidate(scannerID: id, url: $0, root: root, kind: .homeCache)
        }
    }

    /// One entry per cache location. This list is the single source of truth for both the
    /// scanners and the published delete-path manifest — MANIFEST.md is generated from it, so
    /// the document and the behaviour cannot drift apart.
    public struct Definition: Sendable {
        public let id: String
        public let displayName: String
        /// Relative to the user's home directory.
        public let relativePath: String
    }

    public static let definitions: [Definition] = rawDefinitions.map {
        Definition(id: $0.0, displayName: $0.1, relativePath: $0.2)
    }

    /// The cache locations verified readable without any permission in Phase 0.
    public static func standardSet(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [HomeCacheScanner] {
        definitions.map { HomeCacheScanner(id: $0.id, displayName: $0.displayName, root: home.appendingPathComponent($0.relativePath)) }
    }

    private static let rawDefinitions: [(String, String, String)] = [
            ("xcode-derived",   "Xcode DerivedData",        "Library/Developer/Xcode/DerivedData"),
            ("xcode-archives",  "Xcode Archives",           "Library/Developer/Xcode/Archives"),
            ("xcode-devsupport","Xcode iOS DeviceSupport",  "Library/Developer/Xcode/iOS DeviceSupport"),
            ("swiftpm",         "SwiftPM cache",            "Library/Caches/org.swift.swiftpm"),
            ("cocoapods",       "CocoaPods cache",          "Library/Caches/CocoaPods"),
            ("npm",             "npm cache",                ".npm/_cacache"),
            ("yarn",            "Yarn cache",               "Library/Caches/Yarn"),
            ("pip",             "pip cache",                "Library/Caches/pip"),
            ("uv",              "uv cache",                 ".cache/uv"),
            ("go-mod",          "Go module cache",          "go/pkg/mod"),
            ("go-build",        "Go build cache",           "Library/Caches/go-build"),
            ("gradle",          "Gradle cache",             ".gradle/caches"),
            ("maven",           "Maven repository",         ".m2/repository"),
            ("cargo",           "Cargo registry cache",     ".cargo/registry/cache"),
    ]
}

/// Walks a user-selected project tree. Matches only directories whose name is in `ProjectRule`
/// AND that have the corresponding sibling marker file.
public struct ProjectTreeScanner: Scanner {
    public let id = "project-tree"
    public let displayName = "Project build artifacts"
    public var requiresFolderSelection: Bool { true }
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    public func enumerate() throws -> [Candidate] {
        let fm = FileManager.default
        guard let walker = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsPackageDescendants]
        ) else { return [] }

        var found: [Candidate] = []
        for case let url as URL in walker {
            let name = url.lastPathComponent
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard values?.isDirectory == true else { continue }
            if values?.isSymbolicLink == true { walker.skipDescendants(); continue }

            if ProjectRule.neverDescend.contains(name) { walker.skipDescendants(); continue }

            guard let rule = ProjectRule.rule(forDirectoryNamed: name) else { continue }

            let parent = url.deletingLastPathComponent()
            let marker = rule.markers
                .map { parent.appendingPathComponent($0) }
                .first { fm.fileExists(atPath: $0.path) }

            // No marker: this is a directory that merely shares a name. Leave it, keep walking in.
            guard let marker else { continue }

            found.append(Candidate(
                scannerID: rule.scannerID,
                url: url,
                root: root,
                kind: .projectArtifact,
                justification: marker
            ))
            walker.skipDescendants()
        }
        return found
    }
}
