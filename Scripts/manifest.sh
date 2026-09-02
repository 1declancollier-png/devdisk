#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift run -c release devdisk-manifest MANIFEST.md >/dev/null
echo "wrote MANIFEST.md"
