import Foundation

public enum SizeCalculator {
    /// Allocated size on disk, not logical size — what the user actually gets back.
    /// Never follows symlinks, so a link into a huge tree cannot inflate the number.
    public static func allocatedSize(of url: URL, fileManager fm: FileManager = .default) -> Int64 {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isDirectoryKey, .isSymbolicLinkKey]
        guard let values = try? url.resourceValues(forKeys: Set(keys)) else { return 0 }
        if values.isSymbolicLink == true { return 0 }
        if values.isDirectory != true {
            return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        guard let walker = fm.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants]
        ) else { return 0 }

        var total: Int64 = 0
        for case let child as URL in walker {
            guard let v = try? child.resourceValues(forKeys: Set(keys)) else { continue }
            if v.isSymbolicLink == true { walker.skipDescendants(); continue }
            if v.isDirectory != true {
                total += Int64(v.totalFileAllocatedSize ?? v.fileAllocatedSize ?? 0)
            }
        }
        return total
    }

    public static func sized(_ candidates: [Candidate], fileManager fm: FileManager = .default) -> [Candidate] {
        candidates.map {
            var c = $0
            c.sizeBytes = allocatedSize(of: $0.url, fileManager: fm)
            return c
        }
    }

    public static func human(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        f.allowedUnits = [.useGB, .useMB, .useKB]
        return f.string(fromByteCount: bytes)
    }
}
