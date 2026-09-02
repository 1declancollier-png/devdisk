import Foundation

public enum CandidateKind: String, Sendable, Equatable {
    /// Lives under a well-known cache directory in the user's home. No folder selection needed.
    case homeCache
    /// Lives inside a project tree the user explicitly selected.
    case projectArtifact
}

/// One thing the scanner proposes deleting. Proposing is all it does — see `Deleter`.
public struct Candidate: Sendable, Equatable {
    public let scannerID: String
    /// The directory or file to remove.
    public let url: URL
    /// The root this candidate was enumerated under. Deletion is confined to descendants of it.
    public let root: URL
    public let kind: CandidateKind
    /// For `.projectArtifact`: the sibling marker file that proves this is a real build artifact
    /// and not just a directory that happens to share a name. Required — see SafetyGuard.
    public let justification: URL?
    public var sizeBytes: Int64

    public init(
        scannerID: String,
        url: URL,
        root: URL,
        kind: CandidateKind,
        justification: URL? = nil,
        sizeBytes: Int64 = 0
    ) {
        self.scannerID = scannerID
        self.url = url
        self.root = root
        self.kind = kind
        self.justification = justification
        self.sizeBytes = sizeBytes
    }
}
