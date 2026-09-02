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
| `xcode-derived` | `~/Library/Developer/Xcode/DerivedData` |
| `xcode-archives` | `~/Library/Developer/Xcode/Archives` |
| `xcode-devsupport` | `~/Library/Developer/Xcode/iOS DeviceSupport` |
| `xcode-previews` | `~/Library/Developer/Xcode/UserData/Previews` |
| `xcode-doccache` | `~/Library/Developer/Xcode/DocumentationCache` |
| `xcode-logs` | `~/Library/Developer/Xcode/Products` |
| `macos-devsupport` | `~/Library/Developer/Xcode/macOS DeviceSupport` |
| `watchos-devsupport` | `~/Library/Developer/Xcode/watchOS DeviceSupport` |
| `tvos-devsupport` | `~/Library/Developer/Xcode/tvOS DeviceSupport` |
| `visionos-devsupport` | `~/Library/Developer/Xcode/visionOS DeviceSupport` |
| `simulator-caches` | `~/Library/Developer/CoreSimulator/Caches` |
| `swiftpm` | `~/Library/Caches/org.swift.swiftpm` |
| `cocoapods` | `~/Library/Caches/CocoaPods` |
| `npm` | `~/.npm/_cacache` |
| `yarn` | `~/Library/Caches/Yarn` |
| `pip` | `~/Library/Caches/pip` |
| `uv` | `~/.cache/uv` |
| `go-mod` | `~/go/pkg/mod` |
| `go-build` | `~/Library/Caches/go-build` |
| `gradle` | `~/.gradle/caches` |
| `maven` | `~/.m2/repository` |
| `npx` | `~/.npm/_npx` |
| `node-gyp` | `~/Library/Caches/node-gyp` |
| `homebrew` | `~/Library/Caches/Homebrew` |
| `xcode-appcache` | `~/Library/Caches/com.apple.dt.Xcode` |
| `cargo-src` | `~/.cargo/registry/src` |
| `rustup-downloads` | `~/.rustup/downloads` |
| `rustup-tmp` | `~/.rustup/tmp` |
| `bun` | `~/.bun/install/cache` |
| `deno` | `~/Library/Caches/deno` |
| `playwright` | `~/Library/Caches/ms-playwright` |
| `puppeteer` | `~/.cache/puppeteer` |
| `pnpm` | `~/Library/pnpm/store` |
| `cargo` | `~/.cargo/registry/cache` |

## Project build artifacts

Only inside a folder you explicitly pick. A directory is matched **only** when its name appears
below *and* one of the listed marker files sits beside it — a name match alone is never enough.

| Directory | Required sibling marker | Scanner |
|---|---|---|
| `node_modules/` | `package.json` | `node` |
| `.next/` | `package.json` | `node` |
| `.nuxt/` | `package.json` | `node` |
| `.turbo/` | `package.json` | `node` |
| `.parcel-cache/` | `package.json` | `node` |
| `.build/` | `Package.swift` | `swiftpm` |
| `Pods/` | `Podfile` | `cocoapods` |
| `target/` | `Cargo.toml` | `rust` |
| `.venv/` | `pyproject.toml` or `requirements.txt` or `setup.py` | `python` |
| `__pycache__/` | `pyproject.toml` or `requirements.txt` or `setup.py` | `python` |
| `build/` | `build.gradle` or `build.gradle.kts` | `gradle` |

## Never entered

These directories are never descended into, whatever else is true:

- `.git`
- `.hg`
- `.svn`
- `Library`
- `System`

A directory containing `.git` is never proposed for deletion.

## Docker

Reported only. devdisk never runs a Docker command; it shows `docker system prune --all --volumes`
for you to run yourself, because Docker reclaim cannot go to the Trash.

## Guarantees, each an executable check

Run `swift run devdisk-selftest` to verify these yourself.

1. Never touch a path that is not a strict descendant of an enumerated root
2. Never follow a symlink out of that root
3. Never delete a directory containing `.git`
4. Never match a build artifact by directory name alone
5. Validate every item in a batch before removing any — one unsafe item removes nothing
