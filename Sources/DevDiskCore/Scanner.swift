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
        /// Which toolchain writes it.
        public let tool: String
        /// What brings it back after deletion — the answer to "what do I lose?".
        public let regeneratedBy: String
    }

    /// The cache locations verified readable without any permission in Phase 0.
    public static func standardSet(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [HomeCacheScanner] {
        definitions.map { HomeCacheScanner(id: $0.id, displayName: $0.displayName, root: home.appendingPathComponent($0.relativePath)) }
    }

    public static let definitions: [Definition] = [
        .init(id: "xcode-derived", displayName: "Xcode DerivedData", relativePath: "Library/Developer/Xcode/DerivedData",
              tool: "Xcode", regeneratedBy: "the next build — you lose the index, so the first rebuild is slow"),
        .init(id: "xcode-archives", displayName: "Xcode Archives", relativePath: "Library/Developer/Xcode/Archives",
              tool: "Xcode", regeneratedBy: "NOTHING — these are your shipped dSYMs. Review each one before removing it."),
        .init(id: "xcode-devsupport", displayName: "Xcode iOS DeviceSupport", relativePath: "Library/Developer/Xcode/iOS DeviceSupport",
              tool: "Xcode", regeneratedBy: "reconnecting the device, which re-copies symbols (slow, once per OS version)"),
        .init(id: "xcode-previews", displayName: "SwiftUI preview builds", relativePath: "Library/Developer/Xcode/UserData/Previews",
              tool: "Xcode", regeneratedBy: "the next preview render"),
        .init(id: "xcode-doccache", displayName: "Xcode documentation cache", relativePath: "Library/Developer/Xcode/DocumentationCache",
              tool: "Xcode", regeneratedBy: "re-downloading documentation in Xcode"),
        .init(id: "xcode-logs", displayName: "Xcode logs", relativePath: "Library/Developer/Xcode/Products",
              tool: "Xcode", regeneratedBy: "the next build"),
        .init(id: "macos-devsupport", displayName: "macOS DeviceSupport", relativePath: "Library/Developer/Xcode/macOS DeviceSupport",
              tool: "Xcode", regeneratedBy: "reconnecting the device"),
        .init(id: "watchos-devsupport", displayName: "watchOS DeviceSupport", relativePath: "Library/Developer/Xcode/watchOS DeviceSupport",
              tool: "Xcode", regeneratedBy: "reconnecting the device"),
        .init(id: "tvos-devsupport", displayName: "tvOS DeviceSupport", relativePath: "Library/Developer/Xcode/tvOS DeviceSupport",
              tool: "Xcode", regeneratedBy: "reconnecting the device"),
        .init(id: "visionos-devsupport", displayName: "visionOS DeviceSupport", relativePath: "Library/Developer/Xcode/visionOS DeviceSupport",
              tool: "Xcode", regeneratedBy: "reconnecting the device"),
        .init(id: "simulator-caches", displayName: "Simulator caches", relativePath: "Library/Developer/CoreSimulator/Caches",
              tool: "Xcode", regeneratedBy: "the next simulator run"),
        .init(id: "swiftpm", displayName: "SwiftPM cache", relativePath: "Library/Caches/org.swift.swiftpm",
              tool: "Swift Package Manager", regeneratedBy: "the next resolve — re-downloads packages"),
        .init(id: "cocoapods", displayName: "CocoaPods cache", relativePath: "Library/Caches/CocoaPods",
              tool: "CocoaPods", regeneratedBy: "pod install"),
        .init(id: "npm", displayName: "npm cache", relativePath: ".npm/_cacache",
              tool: "npm", regeneratedBy: "the next install — re-downloads tarballs"),
        .init(id: "yarn", displayName: "Yarn cache", relativePath: "Library/Caches/Yarn",
              tool: "Yarn", regeneratedBy: "the next install"),
        .init(id: "pip", displayName: "pip cache", relativePath: "Library/Caches/pip",
              tool: "pip", regeneratedBy: "the next install (pip cache purge does the same thing)"),
        .init(id: "uv", displayName: "uv cache", relativePath: ".cache/uv",
              tool: "uv", regeneratedBy: "the next sync (uv cache clean does the same thing)"),
        .init(id: "go-mod", displayName: "Go module cache", relativePath: "go/pkg/mod",
              tool: "Go", regeneratedBy: "go mod download — note these are read-only, go clean -modcache is the safe way"),
        .init(id: "go-build", displayName: "Go build cache", relativePath: "Library/Caches/go-build",
              tool: "Go", regeneratedBy: "the next build — slower until warm"),
        .init(id: "gradle", displayName: "Gradle cache", relativePath: ".gradle/caches",
              tool: "Gradle", regeneratedBy: "the next build — re-downloads dependencies"),
        .init(id: "maven", displayName: "Maven repository", relativePath: ".m2/repository",
              tool: "Maven", regeneratedBy: "the next build — re-downloads dependencies"),
        .init(id: "npx", displayName: "npx package cache", relativePath: ".npm/_npx",
              tool: "npm", regeneratedBy: "the next npx run — re-downloads the package"),
        .init(id: "node-gyp", displayName: "node-gyp headers", relativePath: "Library/Caches/node-gyp",
              tool: "node-gyp", regeneratedBy: "the next native module build"),
        .init(id: "homebrew", displayName: "Homebrew downloads", relativePath: "Library/Caches/Homebrew",
              tool: "Homebrew", regeneratedBy: "the next install (brew cleanup does the same thing)"),
        .init(id: "xcode-appcache", displayName: "Xcode application cache", relativePath: "Library/Caches/com.apple.dt.Xcode",
              tool: "Xcode", regeneratedBy: "using Xcode"),
        .init(id: "cargo-src", displayName: "Cargo extracted sources", relativePath: ".cargo/registry/src",
              tool: "Cargo", regeneratedBy: "the next build — re-extracted from the registry cache"),
        .init(id: "rustup-downloads", displayName: "rustup downloads", relativePath: ".rustup/downloads",
              tool: "rustup", regeneratedBy: "the next toolchain install"),
        .init(id: "rustup-tmp", displayName: "rustup temp files", relativePath: ".rustup/tmp",
              tool: "rustup", regeneratedBy: "nothing — scratch space"),
        .init(id: "bun", displayName: "Bun install cache", relativePath: ".bun/install/cache",
              tool: "Bun", regeneratedBy: "the next bun install"),
        .init(id: "deno", displayName: "Deno cache", relativePath: "Library/Caches/deno",
              tool: "Deno", regeneratedBy: "the next run — re-downloads modules"),
        .init(id: "playwright", displayName: "Playwright browsers", relativePath: "Library/Caches/ms-playwright",
              tool: "Playwright", regeneratedBy: "playwright install (large re-download)"),
        .init(id: "puppeteer", displayName: "Puppeteer browsers", relativePath: ".cache/puppeteer",
              tool: "Puppeteer", regeneratedBy: "the next install (large re-download)"),
        .init(id: "pnpm", displayName: "pnpm store", relativePath: "Library/pnpm/store",
              tool: "pnpm", regeneratedBy: "the next install (pnpm store prune is gentler)"),
        .init(id: "cargo", displayName: "Cargo registry cache", relativePath: ".cargo/registry/cache",
              tool: "Cargo", regeneratedBy: "the next build — re-downloads crates"),
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

            // Never look *inside* a build-artifact directory, matched or not. Descending into an
            // unmatched node_modules would walk millions of files and could match artifacts
            // nested within it — which are not independently deletable and are not the user's.
            walker.skipDescendants()

            let parent = url.deletingLastPathComponent()
            let marker = rule.markers
                .map { parent.appendingPathComponent($0) }
                .first { fm.fileExists(atPath: $0.path) }

            // No marker: a directory that merely shares the name. Leave it entirely alone.
            guard let marker else { continue }

            found.append(Candidate(
                scannerID: rule.scannerID,
                url: url,
                root: root,
                kind: .projectArtifact,
                justification: marker
            ))
        }
        return found
    }
}
