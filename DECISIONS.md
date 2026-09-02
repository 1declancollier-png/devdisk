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

## 2026-09-01 — Phase 2 done. The app bundle is built without Xcode.

`Scripts/bundle.sh` assembles `devdisk.app` from `swift build` + a generated Info.plist +
`codesign`. Deliberately not `xcodebuild`: requiring a full Xcode install to produce the binary
would make it unreproducible for exactly the people the trust wedge is aimed at — anyone who
wants to check that the delete paths are what `MANIFEST.md` says.

**Verification, and an honest note on it.** Screen recording is denied to the build shell, so
the window was verified through `CGWindowListCopyWindowInfo` (geometry needs no such
permission): 720x560 at (280,151), onscreen, alpha 1.0, layer 0. The reclaimable figure itself
is verified by `devdisk-scan`, which shares the scanner code.

While debugging an apparently missing window I added `NSPrincipalClass` to the plist and
asserted it was required. It is not — I tested by removing it and the window still appears. The
real cause was launching the bare executable from a background shell, which LaunchServices
never activates; `open -a` on the bundle works. The key is kept because Xcode emits it, but the
comment in `bundle.sh` now says what is actually true.

**No delete affordance exists in this build.** Not a hidden flag, not a disabled button —
`Deleter` is in the library and the app never references it.

## 2026-09-01 — Phase 3 done. Deletion exists, guarded and atomic.

Per-item checkboxes only. No select-all, no "clean everything" — SPEC.md §6.1. This costs
nothing in practice because candidates are *top-level children* of a cache, so the real counts
are single digits (npm cache: 3 items, DerivedData: 2). Per-item selection would have been
hostile if candidates were leaf files; they are not.

Deletion is `FileManager.trashItem`, never `unlink`. The confirmation names the count and the
size and says the items can be put back from Finder, because they can.

**Batch deletion is all-or-nothing.** `Deleter` validates every candidate before removing any,
so a selection containing one unsafe item removes nothing at all rather than half-executing.
Mutation-tested: switching to validate-as-you-go turns 2 checks red, one of them on the real
filesystem.

22 checks now, up from 19. The three new ones use the production `TrashRemover` against real
files: an item leaves its original path, lands in the Trash with contents intact, and can be
moved back; unselected siblings are untouched; an invalid batch trashes nothing.
`Deleter.Remover.remove` now returns the destination URL so recoverability is provable rather
than assumed — that return value is also what a future Undo would be built on.

**Not done by me:** the first deletion of real user data. The app is built and verified against
fixtures I created and cleaned up; running it against the actual 275 MB on this machine is the
owner's call, not the build's.

## 2026-09-01 — Phase 4 done. Docker is report-only, and that changes the spec.

**SPEC.md §5 originally said Docker deletion "shells out to `docker system prune` with explicit
flags and shows the exact command first." I did not build that, and the spec is now amended.**

The reason is a conflict inside the spec itself. §5 also says deletion goes to the Trash in v1,
and §6 sells the product on nothing being destroyed without the user seeing it. `docker system
prune` cannot satisfy either: there is no Trash for Docker layers, and the operation is
irreversible. Shipping one irreversible button inside an app whose entire wedge is
recoverability would undercut the wedge for a feature nobody is buying it for.

So v1 reports Docker reclaim, shows `docker system prune --all --volumes` as copyable text, and
does not execute it. Docker is never a `Candidate`, never selectable, and never reaches
`Deleter`. **This is a product decision, not a technical limit — reverse it if you disagree.**

**A real trap, worth remembering.** A GUI app launched from Finder inherits a minimal PATH
(`/usr/bin:/bin:/usr/sbin:/sbin`), so `docker` is essentially never on it even when installed.
`DockerProbe` searches the actual install locations — Homebrew (both architectures), Docker
Desktop's bundled binary, Rancher Desktop, `~/.docker/bin`. A PATH lookup would have silently
reported "no Docker" to most users who have it. Probing runs with a 4-second hard timeout so a
wedged daemon cannot hang the UI.

**Bookmarks are plain, not security-scoped.** Security scope only means something inside the App
Sandbox, and this app is deliberately unsandboxed (§3). A plain bookmark still survives the
folder being moved or renamed, which is the part that matters.

**Two real bugs the tests caught.** Resolving a bookmark returns the canonical path
(`/private/var/…`) while a freshly-picked URL is the lexical one (`/var/…`). Comparing them raw
meant duplicate roots were recorded and `remove` silently matched nothing — a user could add the
same folder repeatedly and never delete it. Both sides are now normalised. This would have hit
anyone whose projects live under a symlinked path.

28 checks, up from 22.

## 2026-09-01 — Phase 5 blocked on an Apple Developer account; manifest done anyway.

Developer ID signing and notarization need the $99/yr account, which does not exist yet.
Without it macOS Gatekeeper blocks the download outright, so distribution cannot proceed.
Sparkle, hash publication and the signed-build gate all wait on that purchase.

The one Phase 5 item that needs no account is done, and it is the most important one:
**MANIFEST.md is generated from the scanner definitions, not written by hand.**
`HomeCacheScanner.definitions` and `ProjectRule.all` are now the single source of truth for
both the scanners and the published document, so the two cannot drift.
`Scripts/check-manifest.sh` regenerates and diffs; verified it rejects a tampered manifest.
Wired into CI alongside the 28 safety checks and a no-Xcode bundle build.

## 2026-09-01 — Scanner never enters a build-artifact directory, matched or not.

Previously the walker only stopped descending after a *successful* match. An unmatched
`node_modules` — one with no sibling `package.json`, e.g. a vendored or committed copy — was
walked into. Two consequences, one slow and one wrong:

- It walks every file in a directory that by definition contains hundreds of thousands of them.
- It could match an artifact *nested inside* that directory and propose deleting it. Verified:
  with the old behaviour the suite reports
  `ws/vendored/node_modules/inner/node_modules` as a deletion candidate. That is not
  independently deletable and it is not the user's to remove.

Now the walker skips descendants of any rule-named directory before deciding whether it matches.
Two checks cover it; mutation-tested by restoring the old ordering, which turns one red.

30 checks, up from 28. MIT LICENSE added to match the Homebrew formula's claim.
