#!/usr/bin/env bash
# Builds the patched ReSkateLauncher.exe on Windows (Visual Studio 2022) into
# OUT (default out/). Run from Git Bash; the GitHub Windows runners have
# everything it needs.
#
# Usage: scripts/build-launcher.sh [OUT]
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$root/out}"
src="$root/build/ReSkate"
py="$(command -v python3 || command -v python)"
version="$("$py" -c 'import json,sys; print(json.load(open(sys.argv[1]))["tag"].lstrip("v"))' "$root/upstream.json")"

"$root/scripts/prepare.sh" "$src"
cd "$src"
# Only the launcher is built here, so the Spotify device (cargo, librespot) stays off.
cmake --preset vs2022-x64 -DDINGOSDK_VERSION="$version" -DDINGOSDK_CARGO=OFF
cmake --build --preset release --target dingosdk_launcher --parallel
mkdir -p "$out"
cp build/vs2022-x64/Release/ReSkateLauncher.exe "$out/"
echo "Built $out/ReSkateLauncher.exe (ReSkate $version)"
