# devdisk

Finds the developer build artifacts and package caches eating your disk — and shows you every
path before it deletes anything.

Working name. See `SPEC.md` §10 before shipping under it.

## Status

- **Phase 0** ✅ — needs no Full Disk Access. Proven, not assumed: `tools/phase0/`
- **Phase 1** ✅ — scanner core + 19 safety checks, mutation-tested
- **Phase 2** ✅ — SwiftUI app, dry-run only, builds without Xcode
- **Phase 3** ✅ — deletion: per-item selection, move to Trash, all-or-nothing batches
- **Phase 4** ✅ — Docker report, remembered project folders
- **Phase 5** — ship (blocked: needs an Apple Developer account). Manifest + CI done.

## Install

```
brew install OWNER/tap/devdisk
devdisk ~/Developer
```

Builds from source, so it needs no code signing and never meets Gatekeeper. The `.app` is a
separate download once it is notarized.

## Run it from a checkout

```
swift run devdisk-scan                    # dry run, home caches only
swift run devdisk-scan ~/Developer        # plus a project tree
swift run devdisk-selftest                # the safety gate; non-zero exit on failure

./Scripts/bundle.sh                       # build devdisk.app (no Xcode required)
open .build/devdisk.app
```

`devdisk-scan` has no delete path compiled in — the CLI can only ever report. The app can
delete, one ticked item at a time, always to the Trash, and a batch containing anything unsafe
removes nothing at all.

## The five invariants

Every one is an executable check in `Sources/devdisk-selftest`:

1. Never touch a path that is not a strict descendant of an enumerated root
2. Never follow a symlink out of that root
3. Never delete a directory containing `.git`
4. Never match a build artifact by directory name alone — a sibling marker file is required
5. Deletion is validated first, batched atomically, and goes to the Trash — never `unlink`

## Documents

- `SPEC.md` — the build contract: scope, non-goals, phases, gates
- `DECISIONS.md` — append-only, why things are the way they are
- `MANIFEST.md` — every path the app can ever delete, generated from the code
- `RESEARCH.md` — competitive landscape, fact-checked; read before arguing with the non-goals
