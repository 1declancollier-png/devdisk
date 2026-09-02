# Naming — resolved 2026-09-02

**Decision: keep `devdisk`.** It is no longer a placeholder.

Twelve candidates were checked across domains (RDAP), GitHub, npm, PyPI, crates.io, Homebrew,
X, Bluesky, USPTO, and searchability. Nine were dead on arrival. Verified with controls in both
directions — a known-registered name and a nonsense string — because a lookup that returns the
same answer for everything is a broken command, not a finding. (The first pass here *was*
broken: `rdap.org` 302-redirects, and without following redirects every domain looked identical
including the control.)

## Why not the poetic names

The metaphor family was "material that accumulates and gets cleared away." It reads well and
fails in practice:

| Name | Blocking reason |
|---|---|
| `chaff` | crates.io `chaff` is **already a shipped dev-disk reclaimer CLI** — same product, same category, same metaphor |
| `backfill` | `git backfill` has been a Git built-in since 2.49.0. The CLI name is already a Git subcommand |
| `winnow` | crates.io `winnow` has 853M downloads — it is in the target audience's lockfiles already |
| `scree` | Search engines rewrite the query to *screen*. Not an SEO problem, an autocorrect problem |
| `husk` | Permanent stemming collision with `husky` (35k stars) in the same vocabulary |
| `sluice` | crates.io `sluice`, 16.4M downloads, transitive dep of `isahc` |
| `moraine` | Two live products already in AI dev tooling; `moraine-cli` ranks #1 |
| `silt` | `silt.app` is a live company, plus a pending class-42 AI-SaaS trademark |
| `dross` | Both domains registered; also names worthlessness, which transfers to the product |
| `tailings` / `overburden` | `.app` free but GitHub handle occupied; and developers hear "tailings" as `tail -f` |
| `cruftwork` | Genuinely free everywhere — but `cruft.app` and `crufti.app` are Mac cleanup apps registered in the last nine months. The name is free; the shelf is not |

## Why `devdisk`

Verified free 2026-09-02: **`devdisk.app`**, GitHub org, npm, crates.io, PyPI, Homebrew formula
and cask. `devdisk.com` is registered, which the spec allows — it requires `.app` *or* `.com`.

Against the spec's constraints in §10: not feature-level (it survives adding a second tool);
none of the banned cleaner register; spells from sound with no ambiguity; no `Mac-`/`i-`/`Notch-`
prefix; short to type daily; no scope overclaim.

The argument that settled it: the product's pitch is *"you can verify exactly what I delete."*
An opaque poetic name asks the buyer to take one more thing on faith at the moment you are
arguing for transparency. Boring is not the failure mode here — unexplainable is. Every poetic
candidate carries an explanation tax paid in every README, every HN comment, every reply, in
the only channels available.

Counter-argument, recorded honestly: Mac utilities do sustain opaque names — Little Snitch, LuLu,
DaisyDisk. Those earned recall through years of distribution this project does not have.

## Not checked

Trademark registers outside the US; common-law marks; Mac App Store name reservations; whether
the X handle 404 means claimable or merely deactivated. Revisit after the first ten paying
customers — the name is the cheapest thing to change before launch and the most expensive after.
