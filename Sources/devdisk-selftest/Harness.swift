import Foundation
import DevDiskCore

/// Minimal assertion harness. No XCTest, no swift-testing — both require a full Xcode install,
/// and the safety invariants must be runnable by anyone with only Command Line Tools.
enum Harness {
    nonisolated(unsafe) static var failures: [String] = []
    nonisolated(unsafe) static var passed = 0
    nonisolated(unsafe) static var current = ""

    static func fail(_ msg: String, _ line: Int) {
        failures.append("\(current) (line \(line)): \(msg)")
    }

    static func expect(_ cond: Bool, _ msg: String, line: Int = #line) {
        if !cond { fail(msg, line) }
    }

    static func expectEqual<T: Equatable>(_ got: T, _ want: T, _ msg: String = "", line: Int = #line) {
        if got != want { fail("\(msg.isEmpty ? "" : msg + " — ")expected \(want), got \(got)", line) }
    }

    /// Asserts `body` throws a SafetyViolation the matcher accepts. Anything else is a failure,
    /// including succeeding — a guard that silently permits is the bug this suite exists to catch.
    static func expectViolation(
        _ describe: String,
        line: Int = #line,
        matching match: (SafetyViolation) -> Bool,
        _ body: () throws -> Void
    ) {
        do {
            try body()
            fail("expected \(describe), but the call succeeded", line)
        } catch let v as SafetyViolation {
            if !match(v) { fail("expected \(describe), got \(v)", line) }
        } catch {
            fail("expected \(describe), got unexpected error: \(error)", line)
        }
    }

    static func test(_ name: String, _ body: () throws -> Void) {
        current = name
        let before = failures.count
        do { try body() } catch { fail("threw unexpectedly: \(error)", 0) }
        if failures.count == before { passed += 1 }
    }

    static func report() -> Never {
        print("")
        if failures.isEmpty {
            print("  ✓ \(passed) safety invariant checks passed")
            print("")
            exit(0)
        }
        print("  ✗ \(failures.count) failure(s), \(passed) passed")
        for f in failures { print("    - \(f)") }
        print("")
        exit(1)
    }
}

/// Records what it was asked to remove; never touches the filesystem.
/// Lets the suite prove the guard runs *before* anything is removed.
final class SpyRemover: Deleter.Remover, @unchecked Sendable {
    var removed: [URL] = []
    @discardableResult
    func remove(_ url: URL) throws -> URL? { removed.append(url); return nil }
}

/// Fresh scratch tree per test.
struct Fixture {
    let root: URL
    private let fm = FileManager.default

    init() throws {
        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("devdisk-selftest-\(UUID().uuidString)")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
    }

    @discardableResult
    func dir(_ path: String) throws -> URL {
        let u = root.appendingPathComponent(path)
        try fm.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    @discardableResult
    func file(_ path: String, _ contents: String = "x") throws -> URL {
        let u = root.appendingPathComponent(path)
        try fm.createDirectory(at: u.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: u, atomically: true, encoding: .utf8)
        return u
    }

    func link(_ at: String, to target: URL) throws -> URL {
        let u = root.appendingPathComponent(at)
        try fm.createSymbolicLink(at: u, withDestinationURL: target)
        return u
    }

    func exists(_ url: URL) -> Bool { fm.fileExists(atPath: url.path) }
    func cleanup() { try? fm.removeItem(at: root) }
}
