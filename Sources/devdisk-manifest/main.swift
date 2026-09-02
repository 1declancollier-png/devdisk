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
