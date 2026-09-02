# Build spec — developer disk reclaimer for macOS

**Status:** ready to build. Working name `devdisk` (folder name only — see Naming).
**Source of the competitive decisions:** `RESEARCH.md` in this folder. Read it before arguing with the non-goals.

---

## 1. What this is

A macOS app that finds reclaimable developer build artifacts and package caches, shows you **every path it intends to touch before it touches anything**, and deletes only what you tick.

Positioning sentence (the thing a stranger repeats):

> Finds the 200 GB of DerivedData, node_modules and Docker images eating your disk — and shows you every path before it deletes anything.

The product is not "a cleaner." It is a **verifiable** cleaner. Every incumbent in this space (CodeCleaner, DevClean, ClearDisk, MacPaw's `cleanmymac-cli`) asks to be trusted. This one is checkable. That is the entire differentiator — the market is not empty, so the wedge is trust, not novelty.

## 2. Non-goals — explicit, and not open for reinterpretation mid-build

Do not build, do not scaffold "for later", do not leave hooks for:

- Any general system cleaner behaviour — browser caches, mail attachments, iOS backups, Photos, language files, "system junk"
- Wallpaper, notch, menu bar hiding, window management, toggles, per-app volume, brightness
- Any "speed up / optimize / boost your Mac" claim, in code, copy, or UI string
- Telemetry, analytics, crash reporting that phones home by default, or any account/login
- Auto-deletion, scheduled deletion, background deletion, or a "clean now" button that acts without a reviewed selection
- Any network call except the Sparkle update check

Rationale in `RESEARCH.md` § "Do not build". A cleaner that grows toward the CleanMyMac feature set inherits the CleanMyMac trust problem, which is the one thing this product is selling against.

## 3. Stack

- Swift 6, SwiftUI, macOS 14+ minimum
- No third-party runtime dependencies except **Sparkle** (updates)
- Distribution: **direct download only.** Developer ID signed + notarized. Not the Mac App Store — the scanner reads outside a sandbox container.
- Build: SwiftPM package + Xcode project, `xcodebuild` from a clean checkout must work

## 4. Permissions — minimum viable, verified in Phase 0

**SETTLED — Phase 0 passed, 2026-09-01. This app needs NO Full Disk Access.**

Tested on macOS 26.6.2 from a fresh ad-hoc-signed `.app` bundle with zero TCC grants: every
user-home cache target read fine, while both FDA control paths were denied. Evidence and
reproduction in `tools/phase0/`; reasoning in `DECISIONS.md`.

So: **no FDA prompt, no permission onboarding, nothing for the user to grant.** Project-tree
scanning uses `NSOpenPanel` + security-scoped bookmarks — user selection *is* the grant, so
`~/Desktop`/`~/Documents`/`~/Downloads` need no separate prompt either.

This is now the sharpest line on the download page: *"Needs no Full Disk Access. Nothing to
grant."* No incumbent can say it.

Hard rules regardless of outcome:

- No permission prompt fires before the user has seen a real result
- Prompts are per-feature, at point of use, never batched at launch
- Declining any permission disables exactly one scanner and nothing else
- Each prompt is preceded by an in-app sentence naming what is read and what is not

## 5. Scanners

Each scanner is an isolated module: `id`, `displayName`, `requiresPermission`, `enumerate() -> [Candidate]`, `isSafeToDelete(Candidate) -> Bool`.

**User-home caches** (no folder selection needed):
- `~/Library/Developer/Xcode/DerivedData`
- `~/Library/Developer/Xcode/Archives`
- `~/Library/Developer/Xcode/iOS DeviceSupport`
- `~/Library/Developer/CoreSimulator/Devices` — **unavailable/orphaned simulators only**
- `~/Library/Caches/org.swift.swiftpm`, `~/Library/Caches/CocoaPods`
- `~/.npm/_cacache`, `~/Library/Caches/Yarn`, pnpm store
- `~/Library/Caches/pip`, `~/.cache/uv`
- `~/go/pkg/mod`, `~/Library/Caches/go-build`
- `~/.gradle/caches`, `~/.m2/repository`
- `~/.cargo/registry/cache`
- Homebrew: report only what `brew cleanup -n` lists

**Project-tree scanners** (require a user-selected root via `NSOpenPanel`):
- `node_modules`, `.next`, `.nuxt`, `.turbo`, `.parcel-cache`
- `.build` (SwiftPM), `Pods`
- `target` (Rust — only when a sibling `Cargo.toml` exists)
- `.venv`, `__pycache__`
- `build`, `.gradle` (only when a sibling `build.gradle*` exists)

**Docker:** report only, via `docker system df`. Deletion shells out to `docker system prune` with explicit flags and shows the exact command first. If the Docker CLI is absent, the scanner is hidden — never an error dialog.

**Safety invariants — every one is a test:**
- Never delete a path that is not a descendant of an enumerated candidate root
- Never follow symlinks out of the candidate root
- Never delete a directory containing a `.git` directory
- Never delete a path matched only by name — every match needs its sibling marker file (`Cargo.toml`, `package.json`, `build.gradle`, etc.)
- Deletion goes to the **Trash** (`NSFileManager.trashItem`), never `unlink`, in v1

## 6. Trust artifacts — shipped requirements, not marketing

These are acceptance criteria. The build is not done without them.

1. **Dry-run by default.** First run enumerates and deletes nothing. Deletion requires an explicit per-item selection. There is no "clean everything" affordance in v1.
2. **Delete-path manifest.** `MANIFEST.md` in this repo lists every path pattern any scanner can ever match, generated from the scanner definitions by a build script — not hand-written, so it cannot drift. CI fails if the checked-in manifest differs from the generated one.
3. **Published hash + signature.** Every release publishes SHA-256 and the exact `codesign -dv --verbose=4` / `spctl -a -vvv -t install` output a skeptic can reproduce in 30 seconds.
4. **Stated network behaviour.** "No outbound connections except the update check at `<exact URL>`" — falsifiable with Little Snitch or LuLu. Must be literally true.
5. **Ownership-transfer policy**, written, on the site, at launch: what happens to licences if the app is sold or discontinued. No incumbent does this; Bartender is why it matters.
6. **No account, no email, to run the trial.**

## 7. First run — the sequence, in order

1. Window opens, scan of user-home caches starts immediately, no prompt, no onboarding carousel
2. Within ~60 seconds: **a number** — "84.2 GB reclaimable" — broken down by scanner
3. Nothing is selected. Nothing is deleted. Every row expands to the literal paths and their sizes
4. Only if the user chooses a project scan does an `NSOpenPanel` appear, and the reason is stated first

The number before any permission ask is the activation moment. Do not reorder this.

## 8. Phases and acceptance gates

**Phase 0 — permission reality check. ✅ DONE 2026-09-01.** No FDA required; see `DECISIONS.md` and `tools/phase0/`. Re-run the probe on macOS 14/15 when a machine is available.

**Phase 1 — scanner core, no UI. ✅ DONE 2026-09-01.** Scanner protocol, 14 user-home scanners, project-tree scanner, sizing, `SafetyGuard`, `Deleter`.
*Gate:* `swift run devdisk-selftest` — 19 checks green, covering every invariant in §5 and its negative case. Not `swift test`: XCTest ships with Xcode and this builds under Command Line Tools alone (see `DECISIONS.md`). Suite is mutation-tested.

**Phase 2 — UI, dry-run only.** The §7 sequence. Expandable path lists. No delete button exists yet.
*Gate:* clean checkout → `xcodebuild` → launch → a real number on a real machine in under 60 s, with no permission prompt.

**Phase 3 — deletion.** Per-item selection, move-to-Trash, undo via Finder.
*Gate:* a test proving deletion never touches a path outside the selected candidates; manual verification that every deleted item is recoverable from Trash.

**Phase 4 — Docker + project scanners.** Folder selection, security-scoped bookmarks, Docker report-and-prune.
*Gate:* Docker absent → scanner hidden, no error. Bookmark survives relaunch.

**Phase 5 — ship.** Sparkle, Developer ID, notarization, manifest generation in CI, the §6 artifacts.
*Gate:* download on a bare machine with no dev tools, first launch clean, `spctl` output matches what the site publishes.

## 9. Pricing and free tier — decided, build accordingly

- **One-time purchase with paid major versions** (Sketch / Kaleidoscope model). Not a subscription — see `RESEARCH.md` for why this specific product shape churns under monthly billing.
- Licence: offline-verifiable key. No server round-trip to run the app.
- Trial: fully functional, time-limited, **no card, no account**.
- Free companion tool at the top of the funnel: the port-killer (`kill process on port`) from `RESEARCH.md` §17 — small, dev-native, needs no scary permission. Ships as a separate free download, not a crippled tier of this app.

## 10. Naming

Unresolved and blocking for launch, not for building. Constraints:

- Not feature-level — must survive adding a second tool
- Avoid the entire MacKeeper lexical register: no *Clean, Sweep, Optimizer, Booster, Guard, Master, Doctor, Genius, Pro*
- Unambiguous spelling from sound (it travels through comments and podcasts)
- Searchable as a bare string — coined or compound, not a dictionary word
- `.app`/`.com` + GitHub org + one social handle all free simultaneously
- No `Mac-` / `i-` / `Notch-` prefixes
- Legible as one glyph at 16 pt

`devdisk` is the folder name. Do not ship it.

## 11. Out of scope for this spec

Marketing execution (channels and launch sequence are in `RESEARCH.md`), the port-killer's own spec, and anything in §2.
