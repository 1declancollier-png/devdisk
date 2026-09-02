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
| `~/Library/Developer/Xcode/DerivedData` | Xcode | the next build — you lose the index, so the first rebuild is slow |
| `~/Library/Developer/Xcode/Archives` | Xcode | NOTHING — these are your shipped dSYMs. Review each one before removing it. |
| `~/Library/Developer/Xcode/iOS DeviceSupport` | Xcode | reconnecting the device, which re-copies symbols (slow, once per OS version) |
| `~/Library/Developer/Xcode/UserData/Previews` | Xcode | the next preview render |
| `~/Library/Developer/Xcode/DocumentationCache` | Xcode | re-downloading documentation in Xcode |
| `~/Library/Developer/Xcode/Products` | Xcode | the next build |
| `~/Library/Developer/Xcode/macOS DeviceSupport` | Xcode | reconnecting the device |
| `~/Library/Developer/Xcode/watchOS DeviceSupport` | Xcode | reconnecting the device |
| `~/Library/Developer/Xcode/tvOS DeviceSupport` | Xcode | reconnecting the device |
| `~/Library/Developer/Xcode/visionOS DeviceSupport` | Xcode | reconnecting the device |
| `~/Library/Developer/CoreSimulator/Caches` | Xcode | the next simulator run |
| `~/Library/Caches/org.swift.swiftpm` | Swift Package Manager | the next resolve — re-downloads packages |
| `~/Library/Caches/CocoaPods` | CocoaPods | pod install |
| `~/.npm/_cacache` | npm | the next install — re-downloads tarballs |
| `~/Library/Caches/Yarn` | Yarn | the next install |
| `~/Library/Caches/pip` | pip | the next install (pip cache purge does the same thing) |
| `~/.cache/uv` | uv | the next sync (uv cache clean does the same thing) |
| `~/go/pkg/mod` | Go | go mod download — note these are read-only, go clean -modcache is the safe way |
| `~/Library/Caches/go-build` | Go | the next build — slower until warm |
| `~/.gradle/caches` | Gradle | the next build — re-downloads dependencies |
| `~/.m2/repository` | Maven | the next build — re-downloads dependencies |
| `~/.npm/_npx` | npm | the next npx run — re-downloads the package |
| `~/Library/Caches/node-gyp` | node-gyp | the next native module build |
| `~/Library/Caches/Homebrew` | Homebrew | the next install (brew cleanup does the same thing) |
| `~/Library/Caches/com.apple.dt.Xcode` | Xcode | using Xcode |
| `~/.cargo/registry/src` | Cargo | the next build — re-extracted from the registry cache |
| `~/.rustup/downloads` | rustup | the next toolchain install |
| `~/.rustup/tmp` | rustup | nothing — scratch space |
| `~/.bun/install/cache` | Bun | the next bun install |
| `~/Library/Caches/deno` | Deno | the next run — re-downloads modules |
| `~/Library/Caches/ms-playwright` | Playwright | playwright install (large re-download) |
| `~/.cache/puppeteer` | Puppeteer | the next install (large re-download) |
| `~/Library/pnpm/store` | pnpm | the next install (pnpm store prune is gentler) |
| `~/.cargo/registry/cache` | Cargo | the next build — re-downloads crates |

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
| `node_modules/` | `package.json` | node |
| `.next/` | `package.json` | node |
| `.nuxt/` | `package.json` | node |
| `.turbo/` | `package.json` | node |
| `.parcel-cache/` | `package.json` | node |
| `.build/` | `Package.swift` | swiftpm |
| `Pods/` | `Podfile` | cocoapods |
| `target/` | `Cargo.toml` | rust |
| `.venv/` | `pyproject.toml` or `requirements.txt` or `setup.py` | python |
| `__pycache__/` | `pyproject.toml` or `requirements.txt` or `setup.py` | python |
| `build/` | `build.gradle` or `build.gradle.kts` | gradle |

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
