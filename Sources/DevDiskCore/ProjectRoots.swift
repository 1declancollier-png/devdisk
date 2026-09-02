import Foundation

/// Remembers the folders the user picked, so they do not re-pick them every launch.
///
/// These are plain bookmarks, not security-scoped ones. Security scope only means anything
/// inside the App Sandbox, and this app is deliberately not sandboxed (SPEC.md §3 — a sandboxed
/// build cannot read the caches at all, whatever the user grants). A plain bookmark still
/// survives the folder being moved or renamed, which is the part that matters here.
public struct ProjectRoots {
    private let defaultsKey = "devdisk.projectRoots.v1"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Resolving a bookmark returns the canonical path (/private/var/…), while a URL the user
    /// just picked is usually the lexical one (/var/…). Comparing them raw silently fails to
    /// match, which shows up as duplicate roots that can never be removed. Normalise both sides.
    private func key(_ url: URL) -> String {
        URL(fileURLWithPath: url.path).standardizedFileURL.resolvingSymlinksInPath().path
    }

    public func load() -> [URL] {
        guard let blobs = defaults.array(forKey: defaultsKey) as? [Data] else { return [] }
        var urls: [URL] = []
        var stillValid: [Data] = []
        for blob in blobs {
            var stale = false
            guard let url = try? URL(resolvingBookmarkData: blob, options: [], bookmarkDataIsStale: &stale),
                  FileManager.default.fileExists(atPath: url.path)
            else { continue }   // folder deleted or unreachable: drop it silently, it is not an error
            urls.append(url)
            stillValid.append(stale ? ((try? url.bookmarkData()) ?? blob) : blob)
        }
        if stillValid.count != blobs.count { defaults.set(stillValid, forKey: defaultsKey) }
        return urls
    }

    public func add(_ url: URL) {
        guard let blob = try? url.bookmarkData() else { return }
        var blobs = defaults.array(forKey: defaultsKey) as? [Data] ?? []
        // De-dupe by resolved path, not by bookmark bytes — the same folder can bookmark differently.
        let existing = Set(load().map(key))
        guard !existing.contains(key(url)) else { return }
        blobs.append(blob)
        defaults.set(blobs, forKey: defaultsKey)
    }

    public func remove(_ url: URL) {
        let blobs = (defaults.array(forKey: defaultsKey) as? [Data] ?? []).filter { blob in
            var stale = false
            let resolved = try? URL(resolvingBookmarkData: blob, options: [], bookmarkDataIsStale: &stale)
            return resolved.map(key) != key(url)
        }
        defaults.set(blobs, forKey: defaultsKey)
    }
}
