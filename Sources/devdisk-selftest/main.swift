import Foundation
import DevDiskCore

// The Phase 1 gate. One check per safety invariant in SPEC.md §5, each with its negative case.
// These make the product's central claim — "it shows you every path and touches nothing else" —
// checkable rather than asserted. Do not weaken them to make a scanner pass.

/// Runs `body` against a fresh scratch tree. Swallows throws into the failure log so each
/// check reads as a straight sequence of assertions rather than a chain of `try`.
func withFixture(_ body: (Fixture) throws -> Void) {
    guard let f = try? Fixture() else { return Harness.fail("could not create fixture", 0) }
    defer { f.cleanup() }
    do { try body(f) } catch { Harness.fail("threw unexpectedly: \(error)", 0) }
}

// MARK: invariant 1 — confined to the enumerated root

Harness.test("candidate outside the root is rejected") {
    withFixture { f in
        let root = try f.dir("root")
        let outside = try f.dir("elsewhere/victim")
        Harness.expectViolation("notDescendantOfRoot") {
            if case .notDescendantOfRoot = $0 { return true }; return false
        } _: {
            try SafetyGuard.validate(Candidate(scannerID: "t", url: outside, root: root, kind: .homeCache))
        }
        Harness.expect(f.exists(outside), "guard must not touch anything")
    }
}

Harness.test("the root itself is rejected") {
    withFixture { f in
        let root = try f.dir("root")
        Harness.expectViolation("isRootItself") {
            if case .isRootItself = $0 { return true }; return false
        } _: {
            try SafetyGuard.validate(Candidate(scannerID: "t", url: root, root: root, kind: .homeCache))
        }
    }
}

Harness.test("a descendant of the root is accepted") {
    withFixture { f in
        let root = try f.dir("root")
        let child = try f.dir("root/DerivedData-abc123")
        try SafetyGuard.validate(Candidate(scannerID: "t", url: child, root: root, kind: .homeCache))
    }
}

// MARK: invariant 2 — symlinks may not escape the root

Harness.test("symlink escaping the root is rejected") {
    withFixture { f in
        let root = try f.dir("root")
        let precious = try f.dir("precious")
        try f.file("precious/irreplaceable.txt", "do not delete")
        let bait = try f.link("root/looks-innocent", to: precious)
        Harness.expectViolation("escapesRootViaSymlink") {
            if case .escapesRootViaSymlink = $0 { return true }; return false
        } _: {
            try SafetyGuard.validate(Candidate(scannerID: "t", url: bait, root: root, kind: .homeCache))
        }
        Harness.expect(f.exists(precious), "symlink target must be untouched")
    }
}

Harness.test("symlink staying inside the root is accepted") {
    withFixture { f in
        let root = try f.dir("root")
        let real = try f.dir("root/real")
        let alias = try f.link("root/alias", to: real)
        try SafetyGuard.validate(Candidate(scannerID: "t", url: alias, root: root, kind: .homeCache))
    }
}

// MARK: invariant 3 — never a repository

Harness.test("directory containing .git is rejected") {
    withFixture { f in
        let root = try f.dir("root")
        let repo = try f.dir("root/some-project")
        try f.dir("root/some-project/.git")
        Harness.expectViolation("containsGitRepository") {
            if case .containsGitRepository = $0 { return true }; return false
        } _: {
            try SafetyGuard.validate(Candidate(scannerID: "t", url: repo, root: root, kind: .homeCache))
        }
    }
}

// MARK: invariant 4 — a name match is never enough

Harness.test("node_modules without package.json is not emitted") {
    withFixture { f in
        let root = try f.dir("ws")
        try f.dir("ws/not-really/node_modules/deep")
        let found = try ProjectTreeScanner(root: root).enumerate()
        Harness.expect(found.isEmpty, "matched on directory name alone: \(found.map(\.url.path))")
    }
}

Harness.test("node_modules with package.json is emitted, with its justification") {
    withFixture { f in
        let root = try f.dir("ws")
        try f.file("ws/app/package.json", "{}")
        let nm = try f.dir("ws/app/node_modules/left-pad")
        let found = try ProjectTreeScanner(root: root).enumerate()
        Harness.expectEqual(found.count, 1, "candidate count")
        Harness.expectEqual(found.first?.url.lastPathComponent, "node_modules")
        Harness.expectEqual(found.first?.justification?.lastPathComponent, "package.json")
        Harness.expect(f.exists(nm), "scanning must never modify anything")
        if let c = found.first { try SafetyGuard.validate(c) }
    }
}

Harness.test("rust target/ without Cargo.toml is not emitted") {
    withFixture { f in
        let root = try f.dir("ws")
        try f.dir("ws/somedir/target/release")
        Harness.expect(try ProjectTreeScanner(root: root).enumerate().isEmpty, "matched target/ with no Cargo.toml")
    }
}

Harness.test("rust target/ with Cargo.toml is emitted") {
    withFixture { f in
        let root = try f.dir("ws")
        try f.file("ws/crate/Cargo.toml", "[package]")
        try f.dir("ws/crate/target/release")
        Harness.expectEqual(try ProjectTreeScanner(root: root).enumerate().map(\.scannerID), ["rust"])
    }
}

Harness.test("project artifact with no justification is rejected") {
    withFixture { f in
        let root = try f.dir("ws")
        let nm = try f.dir("ws/app/node_modules")
        Harness.expectViolation("missingMarkerFile") {
            if case .missingMarkerFile = $0 { return true }; return false
        } _: {
            try SafetyGuard.validate(Candidate(scannerID: "node", url: nm, root: root,
                                               kind: .projectArtifact, justification: nil))
        }
    }
}

Harness.test("a marker from another directory is rejected") {
    withFixture { f in
        let root = try f.dir("ws")
        let nm = try f.dir("ws/app/node_modules")
        let stray = try f.file("ws/other/package.json", "{}")
        Harness.expectViolation("markerNotASibling") {
            if case .markerNotASibling = $0 { return true }; return false
        } _: {
            try SafetyGuard.validate(Candidate(scannerID: "node", url: nm, root: root,
                                               kind: .projectArtifact, justification: stray))
        }
    }
}

Harness.test("scanner never descends into .git") {
    withFixture { f in
        let root = try f.dir("ws")
        try f.file("ws/repo/package.json", "{}")
        try f.dir("ws/repo/.git/node_modules")   // decoy inside repository metadata
        let found = try ProjectTreeScanner(root: root).enumerate()
        Harness.expect(!found.contains { $0.url.pathComponents.contains(".git") },
                       "descended into .git: \(found.map(\.url.path))")
    }
}

// MARK: invariant 5 — deletion is guarded, batched atomically, and goes to the Trash

Harness.test("deleter removes nothing when validation fails") {
    withFixture { f in
        let root = try f.dir("root")
        let outside = try f.dir("elsewhere/victim")
        let spy = SpyRemover()
        do {
            try Deleter(remover: spy).delete(
                Candidate(scannerID: "t", url: outside, root: root, kind: .homeCache))
            Harness.expect(false, "delete succeeded on an out-of-root candidate")
        } catch {}
        Harness.expect(spy.removed.isEmpty, "remover was called despite a safety violation")
    }
}

Harness.test("a batch with one bad candidate removes nothing at all") {
    withFixture { f in
        let root = try f.dir("root")
        let good = try f.dir("root/good")
        let bad = try f.dir("elsewhere/bad")
        let spy = SpyRemover()
        do {
            try Deleter(remover: spy).delete([
                Candidate(scannerID: "t", url: good, root: root, kind: .homeCache),
                Candidate(scannerID: "t", url: bad,  root: root, kind: .homeCache),
            ])
            Harness.expect(false, "batch succeeded with an invalid member")
        } catch {}
        Harness.expect(spy.removed.isEmpty, "a partially-valid batch must not half-execute")
    }
}

Harness.test("a valid candidate reaches the remover") {
    withFixture { f in
        let root = try f.dir("root")
        let child = try f.dir("root/derived-abc")
        let spy = SpyRemover()
        try Deleter(remover: spy).delete(
            Candidate(scannerID: "t", url: child, root: root, kind: .homeCache))
        Harness.expectEqual(spy.removed.map(\.lastPathComponent), ["derived-abc"])
    }
}

// MARK: sizing

Harness.test("size ignores symlinked content") {
    withFixture { f in
        let root = try f.dir("root")
        let big = try f.dir("big")
        try f.file("big/payload", String(repeating: "a", count: 400_000))
        _ = try f.link("root/link", to: big)
        let size = SizeCalculator.allocatedSize(of: root)
        Harness.expect(size < 100_000, "symlinked content inflated the figure: \(size) bytes")
    }
}

// MARK: home cache scanner

Harness.test("home cache scanner emits children, never the root") {
    withFixture { f in
        let cache = try f.dir("DerivedData")
        try f.dir("DerivedData/App-abc")
        try f.dir("DerivedData/App-def")
        let found = try HomeCacheScanner(id: "x", displayName: "x", root: cache).enumerate()
        Harness.expectEqual(Set(found.map(\.url.lastPathComponent)), ["App-abc", "App-def"])
        Harness.expect(!found.contains { $0.url == cache }, "emitted the cache root itself")
        for c in found { try SafetyGuard.validate(c) }
    }
}

Harness.test("home cache scanner on a missing directory returns empty") {
    withFixture { f in
        let missing = f.root.appendingPathComponent("nope")
        Harness.expectEqual(try HomeCacheScanner(id: "x", displayName: "x", root: missing).enumerate().count, 0)
    }
}

// MARK: Phase 3 gate — real Trash round-trip, on the real filesystem
//
// These use the production TrashRemover, not the spy. They create their own fixtures and put
// each one back afterwards, so running the suite never leaves litter in the user's Trash.

Harness.test("trashed item leaves its original location and is recoverable") {
    withFixture { f in
        let root = try f.dir("root")
        let doomed = try f.dir("root/doomed")
        try f.file("root/doomed/marker.txt", "recover me")

        let landed = try Deleter().delete(
            Candidate(scannerID: "t", url: doomed, root: root, kind: .homeCache))

        Harness.expect(!f.exists(doomed), "item still at its original path after trashing")
        guard let landed else { return Harness.expect(false, "TrashRemover reported no destination") }
        Harness.expect(FileManager.default.fileExists(atPath: landed.path),
                       "item is not in the Trash at \(landed.path)")
        Harness.expect(FileManager.default.fileExists(atPath: landed.appendingPathComponent("marker.txt").path),
                       "contents did not survive the move")

        // Recoverable: put it back where it came from, exactly as Finder's Put Back would.
        try FileManager.default.moveItem(at: landed, to: doomed)
        Harness.expect(f.exists(doomed), "could not restore from the Trash")
    }
}

Harness.test("deleting a selection leaves unselected siblings untouched") {
    withFixture { f in
        let root = try f.dir("root")
        let picked = try f.dir("root/picked")
        let keepA = try f.dir("root/keep-a")
        let keepB = try f.dir("root/keep-b")
        try f.file("root/keep-a/precious.txt", "must survive")

        let landed = try Deleter().delete([
            Candidate(scannerID: "t", url: picked, root: root, kind: .homeCache)
        ])

        Harness.expect(!f.exists(picked), "selected item was not removed")
        Harness.expect(f.exists(keepA), "an unselected sibling was removed")
        Harness.expect(f.exists(keepB), "an unselected sibling was removed")
        Harness.expect(f.exists(keepA.appendingPathComponent("precious.txt")),
                       "contents of an unselected sibling were touched")

        for u in landed { try? FileManager.default.removeItem(at: u) }
    }
}

Harness.test("a batch containing one unsafe candidate trashes nothing on the real filesystem") {
    withFixture { f in
        let root = try f.dir("root")
        let good = try f.dir("root/good")
        let outside = try f.dir("outside/bystander")
        try f.file("outside/bystander/keep.txt", "untouchable")

        do {
            _ = try Deleter().delete([
                Candidate(scannerID: "t", url: good,    root: root, kind: .homeCache),
                Candidate(scannerID: "t", url: outside, root: root, kind: .homeCache),
            ])
            Harness.expect(false, "batch with an out-of-root member succeeded")
        } catch {}

        Harness.expect(f.exists(good), "a valid item was trashed even though the batch was invalid")
        Harness.expect(f.exists(outside), "the out-of-root item was trashed")
    }
}

// MARK: Phase 4 gate — Docker absence, size parsing, bookmark persistence

Harness.test("absent Docker yields nil, not an error") {
    // On a machine with Docker installed this check is vacuous; it is the absent path that has
    // to be silent, because that is the common case for non-container developers.
    if DockerProbe.locate() == nil {
        Harness.expect(DockerProbe.report() == nil, "reported something with no docker binary present")
    }
}

Harness.test("docker size strings parse to bytes") {
    Harness.expectEqual(DockerProbe.parseSize("1.5GB"), 1_500_000_000, "GB")
    Harness.expectEqual(DockerProbe.parseSize("512.4MB (100%)"), 512_400_000, "MB with percentage suffix")
    Harness.expectEqual(DockerProbe.parseSize("0B"), 0, "zero")
    Harness.expectEqual(DockerProbe.parseSize("garbage"), 0, "unparseable must be 0, never a guess")
    Harness.expect(DockerProbe.parseSize("2.25TB") == 2_250_000_000_000, "TB")
}

Harness.test("project roots survive a relaunch") {
    withFixture { f in
        let suite = UserDefaults(suiteName: "devdisk.selftest.\(UUID().uuidString)")!
        let project = try f.dir("MyProject")

        ProjectRoots(defaults: suite).add(project)
        // A fresh instance reading the same store is exactly what the next launch does.
        let reloaded = ProjectRoots(defaults: suite).load()
        Harness.expectEqual(reloaded.map(\.lastPathComponent), ["MyProject"], "root did not survive")
    }
}

Harness.test("the same folder is never remembered twice") {
    withFixture { f in
        let suite = UserDefaults(suiteName: "devdisk.selftest.\(UUID().uuidString)")!
        let project = try f.dir("MyProject")
        let store = ProjectRoots(defaults: suite)
        store.add(project)
        store.add(project)
        Harness.expectEqual(store.load().count, 1, "duplicate root recorded")
    }
}

Harness.test("a remembered folder that no longer exists is dropped silently") {
    withFixture { f in
        let suite = UserDefaults(suiteName: "devdisk.selftest.\(UUID().uuidString)")!
        let gone = try f.dir("Temporary")
        let store = ProjectRoots(defaults: suite)
        store.add(gone)
        try FileManager.default.removeItem(at: gone)
        Harness.expectEqual(store.load().count, 0, "resolved a bookmark to a deleted folder")
    }
}

Harness.test("forgetting a root removes only that one") {
    withFixture { f in
        let suite = UserDefaults(suiteName: "devdisk.selftest.\(UUID().uuidString)")!
        let a = try f.dir("ProjectA")
        let b = try f.dir("ProjectB")
        let store = ProjectRoots(defaults: suite)
        store.add(a); store.add(b)
        store.remove(a)
        Harness.expectEqual(store.load().map(\.lastPathComponent), ["ProjectB"])
    }
}

Harness.test("never descends into a build-artifact directory, matched or not") {
    withFixture { f in
        let root = try f.dir("ws")
        // An unmatched node_modules (no sibling package.json) containing a nested package that
        // *would* match if the walker went inside. It must not.
        try f.dir("ws/vendored/node_modules")
        try f.file("ws/vendored/node_modules/inner/package.json", "{}")
        try f.dir("ws/vendored/node_modules/inner/node_modules")

        let found = try ProjectTreeScanner(root: root).enumerate()
        Harness.expect(found.isEmpty,
                       "descended into an unmatched artifact directory: \(found.map(\.url.path))")
    }
}

Harness.test("a matched artifact is reported once, not once per nested copy") {
    withFixture { f in
        let root = try f.dir("ws")
        try f.file("ws/app/package.json", "{}")
        try f.file("ws/app/node_modules/dep/package.json", "{}")
        try f.dir("ws/app/node_modules/dep/node_modules")

        let found = try ProjectTreeScanner(root: root).enumerate()
        Harness.expectEqual(found.count, 1, "nested node_modules reported separately")
        Harness.expectEqual(found.first?.url.lastPathComponent, "node_modules")
    }
}

Harness.report()
