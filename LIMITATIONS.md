# Limitations

Written before anyone asked, because all of it is discoverable anyway and saying it first is
cheaper than being caught not saying it.

**It is not signed or notarized.** The Apple Developer Program costs $99/yr and has not been
paid for. This is why the GUI app is not distributed: since macOS Sequoia, opening an unsigned
app means dismissing a dialog, going to System Settings → Privacy & Security, scrolling, and
clicking Open Anyway. The Homebrew CLI has no such problem — it is built from source on your
machine and never acquires a quarantine flag — which is why the CLI ships first.

**One developer, and the project is new.** There is no track record to point at. That is exactly
the situation the generated manifest and the executable checks are meant to compensate for: you
should not have to trust the author, and this is built so you do not have to.

**Docker is report-only.** It measures your Docker usage and prints the prune command for you to
run yourself. Docker's reclaim cannot go to the Trash, so it is not ours to run on your behalf.

**Not everything is covered.** Only the paths in `MANIFEST.md`. Deliberately: a cleaner that
grows toward "system junk" inherits the reputation of every tool that went that way.

**Only tested on macOS 26.** The no-Full-Disk-Access result was verified on 26.6.2. It is
expected to hold on 14 and 15 and has not been confirmed there.

**Sizes are allocated size on disk, not logical size**, and symlinked content is excluded, so
figures can differ from what Finder reports.

**Moving to the Trash does not free disk space.** This is the honest catch in the whole design.
Deleting to the Trash is what makes a mistake recoverable, and recoverable means the bytes are
still on the disk. You have to empty the Trash to actually get the space back — and people run
a disk tool precisely when they have none left. The app says so after every deletion and offers
to open the Trash; it never uses the words "freed" or "reclaimed" for something it only moved.

**APFS snapshots can hold the space even after that.** If Time Machine has taken a local
snapshot, emptying the Trash may still not move the number. `tmutil listlocalsnapshots /` shows
them. That is outside this tool's scope and it will not touch them.
