# Mac Utility Bundle — Feature Inventory

Every feature Mac users actually pay for, with who already owns it and whether it's worth your time.

**Legend:** 🟢 build · 🟡 cheap filler, low differentiation · 🔴 trap (free rival, fragile, or trust-heavy)

---

## 1. Menu bar

| Feature | Incumbent | Verdict |
|---|---|---|
| Hide / collapse menu bar icons | Bartender **$20 one-time + new $15/yr Pro sub**, **Ice (free, OSS — no commits since Sept 2025)**, Hidden Bar (free) | 🟡 **reopening**: free incumbent stalled a full macOS cycle, paid one just went subscription. Still private APIs; screen recording is optional (Accessibility is the required one). |
| Reorder icons, per-app profiles | Bartender | 🟡 only as part of the above |
| Menu bar search | Bartender | 🟡 |
| Auto-hide in fullscreen / per-app rules | Bartender | 🟡 |
| Second menu bar row | Bartender | 🟡 |
| CPU/RAM/net/temp stats | iStat Menus **$11.99 one-time** (not a sub; weather data is a separate $4.99/yr), **Stats (free, OSS)** | 🟡 easy to build, hard to beat free |
| Clock + timezones + agenda | Itsycal (free), Dato **$18** | 🟡 |
| Battery % / health / cycle count | Coconut (free) | 🟢 cheap, everyone wants it |
| Bluetooth device battery levels | scattered | 🟢 genuinely underserved |
| AirPods battery + auto-switch | ToothFairy $6.99 | 🟢 |

## 2. Notch

| Feature | Incumbent | Verdict |
|---|---|---|
| Now-playing / media controls in notch | NotchNook $25, **boring.notch (free, OSS)**, Alcove, MediaMate | 🔴 crowded + free OSS + breaks yearly |
| Notch file shelf (drag files to stash) | NotchNook, Dropover (Pro price is IAP-only, unpublished) | 🟡 |
| Notch calendar / timer / HUD | NotchNook | 🟡 |
| Charging animation + battery HUD | Alcove | 🟡 |
| Camera mirror / face check | NotchNook | 🟡 |
| Black out the notch entirely | free tools | 🟡 trivial, good freebie |

## 3. Toggles (the "One Switch" layer)

One Switch is **$4.99 one-time** (not $10) and already on Setapp. Individually each of these is ~50 lines of code — the value is having all of them in one place.

- Dark mode toggle 🟢
- Keep awake / caffeinate (Amphetamine free, KeepingYouAwake free) 🟢
- Hide desktop icons 🟢
- Empty trash 🟢
- Lock screen / screensaver 🟢
- Do Not Disturb / Focus mode 🟢
- Low Power Mode 🟢
- Night Shift / True Tone 🟢
- Bluetooth / Wi-Fi / AirDrop / Handoff toggles 🟢
- Show hidden files 🟢
- Mute microphone globally 🟢
- Dock autohide toggle 🟢
- Eject all external disks 🟢
- Connect AirPods 🟢
- Toggle Time Machine 🟢

## 4. Window management

| Feature | Incumbent | Verdict |
|---|---|---|
| Snap to halves/quarters, drag-to-edge | **Rectangle (free, OSS)**, Rectangle Pro $9.99, Magnet $4.99, Raycast (free) | 🔴 free wins |
| Saved layouts / workspaces | Moom **$15**, Swish $16 | 🟡 |
| Restore windows after monitor unplug | Stay $15, Display Maid, Moom $15, Snapback, ShiftPlus | 🔴 **4+ vendors — not the gap I claimed** |
| Per-app window rules | BTT | 🟡 |
| Window switcher (per-window alt-tab) | **AltTab (free, OSS)** | 🔴 |
| Tiling WM mode | yabai / Aerospace (free) | 🔴 |

## 5. Wallpaper

| Feature | Incumbent | Verdict |
|---|---|---|
| Video / live wallpapers | Backdrop, Wallper, Wallspace, MacWall, Reactive Wallpaper (all native Mac) | 🔴 **live priced category, not a gap** |
| Web page / shader wallpapers | Plash (free — **source removed, no longer OSS**) | 🟡 |
| Dynamic time-of-day wallpapers | built-in | 🟡 |
| Per-display / per-Space wallpapers | **built into macOS since Lion** (Settings › Wallpaper › Show on all Spaces) | 🔴 only the management UI is left |
| Rotation from folder / Unsplash | many free | 🟡 |
| **Auto-pause on battery, fullscreen, or low power** | Backdrop, MacWall, Wallper, Wallspace, Reactive all ship it | 🔴 **table stakes, not a differentiator** |
| Screensaver-as-wallpaper (Aerial etc.) | Aerial (free, OSS — maintained fork is AerialScreensaver/Aerial) | 🟡 |

## 6. Cleaning & disk

⚠️ Highest trust cost, worst reputation (MacKeeper), needs Full Disk Access. Recommend cutting entirely, **except** the dev-focused slice.

| Feature | Incumbent | Verdict |
|---|---|---|
| Cache / log cleanup | CleanMyMac $39.95/yr **or $119.95 one-time** | 🔴 |
| App uninstaller + leftovers | AppCleaner (free, **last release 2023**), Pearcleaner (free, **Commons Clause — source-available, not OSS**) | 🔴 |
| Duplicate finder | Gemini $23.40/yr **or $44.95 one-time** | 🔴 |
| Large & old file finder | DaisyDisk $9.99 | 🟡 |
| Disk space visualizer | DaisyDisk, GrandPerspective (free) | 🟡 |
| **Dev junk: node_modules, DerivedData, Docker images, pods, .venv** | CodeCleaner, DevClean, ClearDisk (free OSS), **MacPaw's own `cleanmymac-cli`** | 🟡 real buyer, but occupied — and MacPaw is already in this lane |
| Auto-clean rules for Downloads/Trash | Hazel $42 | 🟡 |
| Startup / login item manager | free tools | 🟢 cheap |
| Launch agent & daemon inspector | KnockKnock (free) | 🟡 |

## 7. Performance & hardware

- CPU/GPU/RAM/disk/net graphs — Stats (free) 🟡
- Per-app energy hogs / "what's draining my battery" 🟢
- Temperature + fan control — Macs Fan Control (free) 🟡
- Battery charge limiting to 80% — AlDente (**free tier**; Pro €11.49/yr *or* €23.99 lifetime) 🟢 *popular, people pay*
- Purge / free RAM 🔴 (placebo, hurts credibility)
- Uptime & session stats 🟡

## 8. Clipboard & text

| Feature | Incumbent | Verdict |
|---|---|---|
| Clipboard history (search, images, pins) | Maccy (free on GitHub, $9.99 on MAS), Paste $29.99/yr, Raycast (free) | 🟡 table stakes, can't charge alone |
| Cross-Mac clipboard sync | Paste | 🟢 |
| Text expansion / snippets | TextExpander **$60/user/yr**, Espanso (free, OSS) | 🟡 |
| Paste as plain text hotkey | free | 🟢 cheap crowd-pleaser |
| OCR text from anywhere on screen | TextSniper $7, Raycast (free) | 🟢 very loved feature |
| Color picker + palette history | free | 🟡 |

## 9. Screenshots & screen

| Feature | Incumbent | Verdict |
|---|---|---|
| Annotated screenshots | **CleanShot X $35** one-time + optional $19/yr updates (best-in-class) | 🔴 don't fight CleanShot |
| Scrolling capture | CleanShot | 🔴 |
| Screen recording → GIF | CleanShot, Kap (free, **dead since 2022**) | 🟡 |
| Pin screenshot as floating overlay | CleanShot | 🟡 |
| Per-monitor brightness for external displays | MonitorControl (free, **last release Oct 2024**), Lunar $23 lifetime + free tier | 🟢 huge pain, people pay |
| Dim below minimum brightness | Shady (free, **abandoned 2014**) | 🟢 cheap |
| Cursor highlight / focus spotlight for demos | Presentify $14.99 | 🟡 |
| Screen ruler / pixel measure | free | 🟡 |

## 10. Files & Finder

- File shelf / drag-drop stash — Dropover $10, Yoink $9 🟢 *loved feature*
- Copy path, new file here, open terminal here 🟢 cheap
- Batch rename 🟡
- Auto-sort / folder rules — Hazel $42 🟡
- Recent files quick access 🟡
- Archive/unarchive — Keka (free) 🔴

## 11. Audio

| Feature | Incumbent | Verdict |
|---|---|---|
| Per-app volume control | SoundSource $49 (**needs an audio HAL plugin — heaviest install in this file**) | 🟢 expensive incumbent = room |
| Output device switcher + auto-switch rules | ToothFairy, SoundSource | 🟢 |
| System-wide EQ | eqMac (free) | 🟡 |
| Mic mute hotkey + on-screen indicator | Mutify $9.99 | 🟢 |
| Route audio to multiple outputs | free (Audio MIDI) | 🟡 |

## 12. Keyboard, mouse & gestures

| Feature | Incumbent | Verdict |
|---|---|---|
| **Separate scroll direction for mouse vs trackpad** | Mos (free, **CC BY-NC — non-commercial, cannot be vendored**) | 🟢 top-3 macOS complaint |
| Disable mouse acceleration | free tools | 🟢 |
| Global hotkey manager | BetterTouchTool $15 (2yr) / $25 lifetime | 🟡 |
| Trackpad gestures → actions | BTT $15–25, Swish $16 | 🟡 |
| Key remapping / Caps Lock → Hyper | Karabiner (free) | 🔴 |
| Hot corners with more actions | free | 🟡 |

## 13. Focus & time

- Pomodoro / focus timer 🟡
- App & website blocker — Cold Turkey, Freedom (sub) 🟡
- Automatic time tracking — Timing ~$108/yr ($9/mo billed annually), RescueTime 🟡 (privacy-heavy)
- Break / posture / 20-20-20 eye reminders 🟢 cheap, sticky
- Auto-Focus based on calendar or active app 🟢

## 14. Calendar & meetings

- Menu bar calendar + agenda — Itsycal (free), Dato $10 🟡
- **Next-meeting countdown + one-click Zoom/Meet/Teams join** — MeetingBar (free, OSS) 🟢 very sticky
- World clocks / timezone converter 🟡
- Countdown to date / event 🟡
- Quick-add reminder or note 🟡

## 15. Privacy & security

- Camera/mic in-use indicator + kill switch — OverSight (free, OSS; last release 2024) 🟢
- Clipboard-access alerts 🟡
- Per-app network firewall — Little Snitch $59 🔴 (**not kernel-level since v5 — it's NetworkExtension with a self-serve entitlement**; still large effort)
- Lock folder with Touch ID 🟢
- Auto-lock when you walk away / unlock w/ Watch 🟡
- Secure file shredder 🟡

## 16. Dock & desktop

- Dock autohide speed tweak 🟢 cheap
- Dock spacers / groups 🟡
- Window previews on Dock hover 🟡
- Desktop icon hider + auto-tidy 🟢
- Named Spaces / desktop switcher 🟡
- Sticky notes / scratchpad on desktop 🟡

## 17. Dev-only layer (your best moat)

Nobody bundles these, and devs pay without blinking.

- Kill process on port / localhost port viewer 🟢
- Reclaim DerivedData, node_modules, Docker, Pods, .venv, Gradle 🟢
- Running-simulator launcher 🟢
- Env var / .env manager 🟡
- JSON / base64 / hash / UUID quick tools 🟡
- Git branch + dirty status in menu bar 🟡
- Localhost tunnel + HTTPS cert helper 🟡

---

## Panel review — what survived

Four reviewers (fact-check, strategy, positioning, retention) went at the first draft. Every price and every "gap" above has been corrected. What the review killed:

**All three claimed gaps were occupied.** Window-restore-after-unplug has Stay, Display Maid, Moom, Snapback and ShiftPlus. Video-wallpaper auto-pause is shipped by Backdrop, MacWall, Wallper, Wallspace and Reactive — it's table stakes, not a differentiator. Dev junk cleanup has CodeCleaner, DevClean, ClearDisk, and MacPaw's own `cleanmymac-cli`. The original shortlist's entire moat was three rows of unresearched whitespace, and one of them ("Displaperture-ish") named a corner-rounding utility.

**The six had no shared buyer.** A video-wallpaper buyer and a DerivedData-cleaning iOS dev are different people. Worse, they repel: a developer evaluating a $35 disk tool sees "video wallpapers" and closes the tab. That is negative bundling value.

**The shortlist was the *high*-maintenance subset, not the low one.** DDC/CI brightness, an audio HAL plugin, Accessibility-API window tracking and display-hotplug callbacks — each is a private-ish surface that breaks on OS updates, and none has an upstream OSS community absorbing the damage the way Ice and Rectangle do. Realistic cost: 6–10 weeks a year of pure non-feature work.

**"~50 lines of code" was wrong.** The toggle panel includes Toggle Time Machine, which needs Full Disk Access — dragging back the exact permission the cleaner was cut to avoid. `killall Finder` also can't be sandboxed, which forecloses the Mac App Store for the whole binary and means owning Sparkle, licence keys, EU VAT and chargebacks yourself.

**Subscription is the wrong model for this.** Half the features are set-and-forget (scroll direction is configured once in ten minutes and never thought about again). A monthly charge is a recurring prompt to re-evaluate against a product that supplies no recurring evidence. Precedent: TextExpander, Ulysses and Fantastical all took sustained public backlash moving to subscriptions for exactly this shape of product.

**Correction to earlier advice:** Setapp is **$14.99/mo** now, not $9.99. It still bundles One Switch, NotchNook, CleanMyMac, Gemini, CleanShot X, Bartender Pro, Paste, Yoink, TextSniper, Timing, Swish and AlDente Pro.

## The one genuine reversal

**Menu bar hiding may be reopening.** I told you to skip it because Ice ate the market. Ice's last commit is September 2025 — it has sat out a full macOS release cycle with 415 open issues, while Bartender went to $20 plus a new $15/yr subscription. That is a stalled free incumbent and an annoyed paid one. It is still the private-API treadmill, so this is a flag, not a recommendation.

Same class of error: the network-firewall 🔴 was justified by "kernel-level," which stopped being true at Little Snitch 5. It's NetworkExtension now with a self-serve entitlement. The effort is still large; the stated reason was wrong.

## What to actually do

Ship **one** app, not six. On the panel's evidence the best candidate is still the developer disk tool — real buyer, stated willingness to pay, lowest OS fragility in the file (filesystem paths, not private APIs) — but the pitch can no longer be "nobody owns this." Against CodeCleaner and MacPaw, the differentiator has to be **verifiable trust**, which none of them offer:

- **Dry-run by default.** First run enumerates and deletes nothing.
- **Public delete-path manifest** in a repo — every path pattern the tool will ever touch, browsable without installing anything.
- **Published signature and hash** on the download page, with the `codesign`/`spctl` commands a skeptic can run in 30 seconds.
- **A written ownership-transfer policy.** Nobody in this category does this, and Bartender is why it matters.

Positioning sentence to beat: *"finds the 200GB of DerivedData, node_modules and Docker images eating your disk — and shows you every path before it deletes anything."*

Price: **one-time, with paid major versions** (Sketch/Kaleidoscope model). Not $3/mo. Free companion tool at the top of the funnel — the port-killer from §17 is ideal: small, dev-native, needs no scary permission.

First run must deliver a number before it asks for a single permission. Ask per-feature at point of use, never batched at launch.

## Do not build

Video wallpapers (five native Mac incumbents ship the differentiator), window snapping (Rectangle), annotated screenshots (CleanShot X), key remapping (Karabiner), per-app volume (audio HAL plugin = highest support load per sale in the file), general system cleaner (trust cost > revenue).

## Open questions the panel could not close

- Whether the dev-disk market is big enough to support the revenue target — nobody measured it.
- Whether Setapp would accept a submission (it solves distribution *and* payments, and would tell you within a quarter which features people actually open).
- Current App Store review policy for audio driver extensions.
- One Switch's and Dropover's exact prices (rendered client-side / IAP-only).
