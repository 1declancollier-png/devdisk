#!/bin/bash
# CI gate: the published delete-path list must match the code that does the deleting.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp="$(mktemp -t devdisk-manifest)"
trap 'rm -f "$tmp"' EXIT
swift run -c release devdisk-manifest "$tmp" >/dev/null
if ! diff -u MANIFEST.md "$tmp"; then
  echo ""
  echo "MANIFEST.md is out of date. Run ./Scripts/manifest.sh and commit the result."
  exit 1
fi
echo "MANIFEST.md matches the scanner definitions"
