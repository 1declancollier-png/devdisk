import Foundation

/// A directory name that indicates a build artifact, plus the sibling files that prove it.
/// A name match alone is never sufficient — see SPEC.md §5.
public struct ProjectRule: Sendable, Equatable {
    public let directoryName: String
    public let markers: [String]
    public let scannerID: String

    public static let all: [ProjectRule] = [
        .init(directoryName: "node_modules",   markers: ["package.json"],                                   scannerID: "node"),
        .init(directoryName: ".next",          markers: ["package.json"],                                   scannerID: "node"),
        .init(directoryName: ".nuxt",          markers: ["package.json"],                                   scannerID: "node"),
        .init(directoryName: ".turbo",         markers: ["package.json"],                                   scannerID: "node"),
        .init(directoryName: ".parcel-cache",  markers: ["package.json"],                                   scannerID: "node"),
        .init(directoryName: ".build",         markers: ["Package.swift"],                                  scannerID: "swiftpm"),
        .init(directoryName: "Pods",           markers: ["Podfile"],                                        scannerID: "cocoapods"),
        .init(directoryName: "target",         markers: ["Cargo.toml"],                                     scannerID: "rust"),
        .init(directoryName: ".venv",          markers: ["pyproject.toml", "requirements.txt", "setup.py"], scannerID: "python"),
        .init(directoryName: "__pycache__",    markers: ["pyproject.toml", "requirements.txt", "setup.py"], scannerID: "python"),
        .init(directoryName: "build",          markers: ["build.gradle", "build.gradle.kts"],               scannerID: "gradle"),
    ]

    public static func rule(forDirectoryNamed name: String) -> ProjectRule? {
        all.first { $0.directoryName == name }
    }

    public static func markers(forDirectoryNamed name: String) -> [String] {
        rule(forDirectoryNamed: name)?.markers ?? []
    }

    /// Directories never descended into, whatever else is true.
    public static let neverDescend: Set<String> = [".git", ".hg", ".svn", "Library", "System"]
}
