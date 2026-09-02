# Decisions

Append-only. One entry per decision that would otherwise get re-litigated.

## 2026-09-01 — Build one app, not a six-feature bundle
A four-reviewer panel found all three "market gaps" the bundle rested on were occupied (window-restore: Stay/Display Maid/Moom/Snapback/ShiftPlus; video-wallpaper auto-pause: shipped by all five native competitors; dev-junk: CodeCleaner/DevClean/ClearDisk/MacPaw's own CLI). The six features also had no shared buyer, and the shortlist was the *higher*-maintenance subset. Full record: `RESEARCH.md`.

## 2026-09-01 — Differentiator is verifiable trust, not novelty
The dev-disk market has 4+ competitors including MacPaw. Every one asks to be trusted. Dry-run default, generated delete-path manifest, published hashes, and a written ownership-transfer policy are the wedge. These are build requirements, not marketing.

## 2026-09-01 — One-time price with paid major versions
Not $3/mo. Half the value is delivered on first run; monthly billing on a set-and-forget utility is a recurring prompt to cancel. Precedent: TextExpander, Ulysses, Fantastical backlashes.

## 2026-09-01 — RESOLVED: the scanner needs NO Full Disk Access. Phase 0 gate passed.

**Answer: no.** All user-home cache targets are readable by an app with zero TCC grants.

**Test.** A Swift probe (`tools/phase0/probe.swift`) run two ways on macOS 26.6.2 (25G83): once
inline, and once from an ad-hoc-signed `.app` bundle with a bundle ID macOS had never seen —
i.e. the exact TCC position of a first-run user. Both runs: every target OK, both Full Disk
Access controls DENIED (`NSCocoaErrorDomain 257`).

The controls are what make this trustworthy. `~/Library/Application Support/com.apple.TCC` and
`~/Library/Safari` are FDA-gated; both were refused in both contexts, so the permissive result
on the targets is a real grant, not a runner that already had FDA. Raw output is checked in at
`tools/phase0/result-*.txt`.

Verified readable with no permission at all, no prompt shown: `~/Library/Developer` (and
`Xcode/DerivedData`, `CoreSimulator/Devices`), `~/Library/Caches` (incl. `org.swift.swiftpm`),
`~/.npm/_cacache`, `~/.cargo/registry/cache`.

**Consequences, now binding on the build:**
- The app ships with **no Full Disk Access prompt**. Do not add one. Do not add an onboarding
  step that explains one.
- This is the strongest version of the trust wedge in `SPEC.md` §6 and it should be stated on
  the download page in exactly these terms: *"Needs no Full Disk Access. Nothing to grant."*
  No incumbent can say that.
- Project-tree scanning still goes through `NSOpenPanel` + security-scoped bookmarks. That is
  now a *design* choice, not a permission workaround: folders the user picks are the only
  folders touched, and `~/Desktop` / `~/Documents` / `~/Downloads` never need their own TCC
  prompt because user selection grants access directly.

**Not tested / still open:** macOS 14 and 15 (only 26.6.2 was available here); behaviour under
a Developer ID signature rather than ad-hoc — expected identical, since TCC keys on bundle
identity and grants rather than signing authority, but confirm at first notarized build.

## 2026-09-01 — Phase 1 done. Tests are an executable, not a testTarget.

`swift test` cannot run on this machine: XCTest and swift-testing both ship with Xcode, and
only Command Line Tools are installed. Rather than make the safety gate depend on a 10 GB
install, the invariants live in `Sources/devdisk-selftest` with a ~60-line assertion harness and
no dependencies. `swift run devdisk-selftest` exits non-zero on failure — usable in CI as-is.

19 checks, one per invariant in SPEC.md §5 plus each negative case. **Mutation-tested:**
disabling the symlink-escape guard turns 1 check red; disabling the marker-file requirement
turns 2 red. The suite is not vacuous.

First real dry run (this machine): 275.6 MB across npm cache, SwiftPM cache, DerivedData and
one project artifact. The scanner has no delete path compiled into it at all — not a flag, not
a disabled button. `Deleter` exists in the library and nothing calls it yet.
