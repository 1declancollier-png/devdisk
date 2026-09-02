# Deleting Xcode DerivedData: what breaks, what doesn't, and how much you get back

Short answer: **it is safe.** DerivedData holds build products and the code index. No source
code lives there. Xcode rebuilds all of it.

The real cost is time, not data: your next build is a full one, and the index has to be rebuilt,
so autocomplete and jump-to-definition are degraded for a few minutes on a large project.
Breakpoints, schemes, and workspace settings survive — those live in `.xcodeproj` /
`.xcworkspace` in your project, not here.

## Measure it first

```
du -sh ~/Library/Developer/Xcode/DerivedData
```

## Delete it

```
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

Delete the *contents*, not the directory. Xcode recreates the folder either way, but some setups
get confused if it vanishes mid-session. Quit Xcode first.

To clear just one project, delete only its folder — they are named `ProjectName-<hash>`.

## The directories people miss

DerivedData is rarely the biggest one.

```
du -sh ~/Library/Developer/Xcode/* ~/Library/Developer/CoreSimulator/* 2>/dev/null | sort -h
```

- **`~/Library/Developer/Xcode/iOS DeviceSupport`** — symbol files, one set per iOS version you
  have ever connected a device running. Frequently larger than DerivedData. Safe to delete;
  reconnecting the device re-copies them, which is slow but only once per OS version.
- **`~/Library/Developer/CoreSimulator/Devices`** — every simulator you have ever created,
  including ones for Xcode versions you uninstalled. Clear the dead ones properly:
  ```
  xcrun simctl delete unavailable
  ```
- **`~/Library/Developer/Xcode/UserData/Previews`** — SwiftUI preview builds. Safe.
- **`~/Library/Developer/Xcode/DocumentationCache`** — re-downloadable. Safe.

## The one you should not blind-delete

**`~/Library/Developer/Xcode/Archives`.**

These are your shipped builds, and they contain the dSYMs you need to symbolicate crash reports
from versions already in users' hands. Once an archive is gone, crash reports from that build
are unreadable forever.

Open Xcode → Window → Organizer and look before removing anything. Keep the archives for every
version still in the wild.

This distinction — DerivedData is disposable, Archives is not — is exactly the kind of thing a
size-ranked "biggest folders" cleaner gets wrong, because Archives is often the bigger number.

## Deleted it and the disk is still full?

Two usual causes:

1. **You moved it to the Trash instead of deleting it.** The Trash is still on your disk. Empty it.
2. **Time Machine has a local snapshot** holding the freed blocks:
   ```
   tmutil listlocalsnapshots /
   ```

Finder's "Available" number includes purgeable space and will often disagree with `df -h`.

---

*[devdisk](https://github.com/1declancollier-png/devdisk) encodes exactly the distinction above: DerivedData,
DeviceSupport, previews and the documentation cache are in its
[manifest](../MANIFEST.md); Archives is deliberately flagged as something you review yourself.
The manifest is generated from the source, and CI fails if the two disagree.*
