#!/usr/bin/env bash
# Builds the patched ReSkateLauncher.exe and ReSkate.dll on Windows (Visual
# Studio 2022, Rust) into OUT (default out/). Run from Git Bash; the GitHub Windows runners have
# everything it needs.
#
# Usage: scripts/build.sh [OUT]
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$root/out}"
mkdir -p "$out"
out="$(cd "$out" && pwd)"
src="$root/build/ReSkate"
py="$(command -v python3 || command -v python)"
version="$("$py" -c 'import json,sys; print(json.load(open(sys.argv[1]))["tag"].lstrip("v"))' "$root/upstream.json")"

"$root/scripts/prepare.sh" "$src"
cd "$src"
# Configure links the Spotify device against an import library from the cargo
# registry, so its crates must be there first.
cargo fetch --manifest-path SpotifyHelper/Cargo.toml
cmake --preset vs2022-x64 -DDINGOSDK_VERSION="$version"
cmake --build --preset release --target dingosdk_launcher dingosdk_runtime --parallel
cp build/vs2022-x64/Release/ReSkateLauncher.exe build/vs2022-x64/Release/ReSkate.dll "$out/"
echo "Built ReSkateLauncher.exe and ReSkate.dll in $out (ReSkate $version)"
