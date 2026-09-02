// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DevDisk",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "DevDiskCore", targets: ["DevDiskCore"]),
        .executable(name: "devdisk-scan", targets: ["devdisk-scan"]),
        .executable(name: "devdisk-selftest", targets: ["devdisk-selftest"]),
        .executable(name: "DevDiskApp", targets: ["DevDiskApp"]),
        .executable(name: "devdisk-manifest", targets: ["devdisk-manifest"]),
    ],
    targets: [
        .target(name: "DevDiskCore"),
        .executableTarget(name: "devdisk-scan", dependencies: ["DevDiskCore"]),
        // Safety invariants live in an executable, not a testTarget: XCTest and swift-testing
        // both ship with Xcode, and this project builds under Command Line Tools alone.
        // `swift run devdisk-selftest` is the Phase 1 gate. Exits non-zero on any failure.
        .executableTarget(name: "devdisk-selftest", dependencies: ["DevDiskCore"]),
        .executableTarget(name: "DevDiskApp", dependencies: ["DevDiskCore"]),
        // Generates MANIFEST.md from the scanner definitions. CI fails if the checked-in file
        // differs, so the published list of deletable paths cannot drift from the code.
        .executableTarget(name: "devdisk-manifest", dependencies: ["DevDiskCore"]),
    ]
)
