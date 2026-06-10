#!/bin/bash
# =============================================================================
# build.sh  —  compile both inference programs (run once, from repo root)
# =============================================================================
# Requires: gcc, make, glib-2.0, pkg-config
#   Ubuntu/Debian:  sudo apt install build-essential libglib2.0-dev pkg-config
# =============================================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "==> Building original Mongrail (Mongrail1) ..."
( cd "$HERE/src/mongrail"  && make )

echo "==> Building Mongrail 2.0 ..."
( cd "$HERE/src/mongrail2" && make )

# Fail loudly now rather than mid-pipeline
[[ -x "$HERE/src/mongrail/mongrail"   ]] || { echo "ERROR: mongrail not built";  exit 1; }
[[ -x "$HERE/src/mongrail2/mongrail2" ]] || { echo "ERROR: mongrail2 not built"; exit 1; }
echo "==> OK: src/mongrail/mongrail and src/mongrail2/mongrail2 (+ gendiplo helpers)"
