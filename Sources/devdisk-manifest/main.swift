import Foundation
import DevDiskCore

// Emits MANIFEST.md. Never hand-edit that file — edit the scanner definitions and re-run
// `./Scripts/manifest.sh`. Scripts/check-manifest.sh fails CI when the two disagree.

var out = """
# Delete-path manifest

**Generated from the scanner definitions — do not edit by hand.**
Regenerate with `./Scripts/manifest.sh`; CI fails if this file and the code disagree.

This is every path pattern devdisk can ever propose deleting. Nothing outside this list is
reachable by the app. You can read it without installing anything.

Deletion always moves items to the Trash — never `unlink` — so anything here is recoverable
from Finder.

## Home cache locations

Each entry is scanned for its **immediate children**. The directory itself is never removed.

| Scanner | Path |
|---|---|

"""

for d in HomeCacheScanner.definitions {
    out += "| `\(d.id)` | `~/\(d.relativePath)` |\n"
}

out += """

## Project build artifacts

Only inside a folder you explicitly pick. A directory is matched **only** when its name appears
below *and* one of the listed marker files sits beside it — a name match alone is never enough.

| Directory | Required sibling marker | Scanner |
|---|---|---|

"""

for r in ProjectRule.all {
    let markers = r.markers.map { "`\($0)`" }.joined(separator: " or ")
    out += "| `\(r.directoryName)/` | \(markers) | `\(r.scannerID)` |\n"
}

out += """

## Never entered

These directories are never descended into, whatever else is true:

\(ProjectRule.neverDescend.sorted().map { "- `\($0)`" }.joined(separator: "\n"))

A directory containing `.git` is never proposed for deletion.

## Docker

Reported only. devdisk never runs a Docker command; it shows `\(DockerReport.pruneCommand)`
for you to run yourself, because Docker reclaim cannot go to the Trash.

## Guarantees, each an executable check

Run `swift run devdisk-selftest` to verify these yourself.

1. Never touch a path that is not a strict descendant of an enumerated root
2. Never follow a symlink out of that root
3. Never delete a directory containing `.git`
4. Never match a build artifact by directory name alone
5. Validate every item in a batch before removing any — one unsafe item removes nothing

"""

let dest = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "MANIFEST.md"
try out.write(toFile: dest, atomically: true, encoding: .utf8)

// The same definitions, rendered for humans who are searching a symptom rather than a category.
// This page is the manifest made useful — which is the point: it argues the claim by being
// worth reading even if you never install anything.
var docs = """
# Every developer cache directory on macOS, and what regenerates it

Your disk is full and you want to know what is safe to delete. Here is the complete list for a
Mac with developer tools on it, what each thing is, and — the part nobody publishes — **what you
lose and what brings it back.**

Measure before you delete anything:

```
du -sh ~/Library/Developer/Xcode/DerivedData ~/.npm ~/.cargo ~/.gradle 2>/dev/null
```

| Path | Tool | What you lose |
|---|---|---|

"""
for d in HomeCacheScanner.definitions {
    docs += "| `~/\(d.relativePath)` | \(d.tool) | \(d.regeneratedBy) |\n"
}
docs += """

## Per-project artifacts

These live inside your own projects. Find them before you delete them — and note `-prune`,
without which you recurse into nested copies and the sizes come out wrong:

```
find ~/code -type d -name node_modules -prune -print0 | xargs -0 du -sh | sort -h
```

The safer version, which only touches projects you have not opened in three months:

```
find ~/code -type d -name node_modules -prune -mtime +90 -print
```

| Directory | Only when this sits beside it | Tool |
|---|---|---|

"""
for r in ProjectRule.all {
    docs += "| `\(r.directoryName)/` | \(r.markers.map { "`\($0)`" }.joined(separator: " or ")) | \(r.scannerID) |\n"
}
docs += """

The marker file matters. A directory called `target` is only a Rust build directory if there is
a `Cargo.toml` next to it — otherwise it is somebody's source folder, and deleting it by name is
how people lose work.

## Large things that are NOT caches — do not delete these

The biggest directories on a developer's Mac are usually not caches at all, and every
"reclaim your disk" article that ranks them by size gets this wrong.

| Path | Why it looks tempting | Why you should not |
|---|---|---|
| `~/.rustup` | routinely over 1 GB | Installed Rust toolchains. Deleting it uninstalls your compilers. Use `rustup toolchain list` and remove old ones individually |
| `~/.nvm` | hundreds of MB | Installed Node versions. Use `nvm uninstall <version>` |
| `~/Library/Android/sdk` | several GB | SDK platforms and system images you actually build against |
| `~/.android/avd` | several GB | Your emulator disk images, with their state |
| `~/Library/Developer/Xcode/Archives` | grows forever | **Your shipped dSYMs.** You need these to symbolicate crash reports from released builds |

## Two things that will waste your afternoon

**The Trash does not free space.** Moving 60 GB to the Trash reclaims zero bytes until you empty
it. This catches everybody.

**APFS local snapshots hold space even after that.** If Time Machine has taken one, the number
will not move:

```
tmutil listlocalsnapshots /
```

Finder's "Available" figure includes purgeable space, which is why it often disagrees with `df`.

---

*This table is generated from the source of [devdisk](https://github.com/1declancollier-png/devdisk), a Mac
tool that scans exactly these paths and shows you every one before deleting anything. The
machine-readable version is [MANIFEST.md](../MANIFEST.md), and CI fails if it drifts from the
code. You do not need the tool to use this page.*

"""
try docs.write(toFile: "docs/mac-developer-cache-directories.md", atomically: true, encoding: .utf8)
