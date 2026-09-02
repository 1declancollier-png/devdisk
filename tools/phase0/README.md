# Phase 0 — does the scanner need Full Disk Access?

Reproduce:

```
swiftc -O -o probe probe.swift
./probe /tmp/inline.txt          # inherits the calling process's TCC grants
```

For the decisive run, wrap `probe` in a `.app` bundle with a **bundle ID macOS has never
seen** (append a timestamp), ad-hoc sign it (`codesign --force --deep -s -`), and launch it
with `open -W`. A fresh bundle ID has zero TCC grants, which is what a first-run user has.

The two `control-fda` rows are the test's own validity check: `~/Library/Application
Support/com.apple.TCC` and `~/Library/Safari` are gated behind Full Disk Access. If those
come back OK, the runner has FDA and the result proves nothing — rerun somewhere else.
