#!/usr/bin/env bash
# Sets up ReSkate on an ARM64 Linux handheld (Retroid Pocket 6 with ArmadaOS):
# ReSkate's own release, this repository's patched launcher, and the game
# build ReSkate supports, downloaded with the native ARM64 DepotDownloader
# (the launcher's Windows one crashes under FEX). Then it prints the Steam
# launch option to use. You need skate. in your Steam library.
#
# Usage: scripts/setup-armadaos.sh [DIR]   (default ~/ReSkate)
set -euo pipefail

dir="$(realpath -m "${1:-$HOME/ReSkate}")"
overlay="Ken5998/reskate-arm64"
meta="$(curl -fsSL "https://raw.githubusercontent.com/$overlay/main/upstream.json")"
field() { python3 -c 'import json,sys; print(json.loads(sys.argv[1])[sys.argv[2]])' "$meta" "$1"; }
tag="$(field tag)"; app="$(field steam_app)"; depot="$(field steam_depot)"; manifest="$(field steam_manifest)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

case "$dir" in */steamapps/common/*) echo "Pick a folder outside Steam's library." >&2; exit 1 ;; esac
mkdir -p "$dir"

echo "== ReSkate ${tag#v}"
curl -fL# -o "$work/reskate.zip" \
  "https://github.com/Dingo-Shenanigans/ReSkate/releases/download/$tag/ReSkate-${tag#v}.zip"
python3 -m zipfile -e "$work/reskate.zip" "$dir"

echo "== Patched launcher and ReSkate.dll"
curl -fL# -o "$work/launcher.zip" \
  "https://github.com/$overlay/releases/latest/download/ReSkate-armadaos.zip"
python3 -m zipfile -e "$work/launcher.zip" "$dir"

echo "== skate. build $manifest (about 14 GB; scan the QR code with the Steam app)"
curl -fL# -o "$work/dd.zip" \
  "https://github.com/SteamRE/DepotDownloader/releases/latest/download/DepotDownloader-linux-arm64.zip"
python3 -m zipfile -e "$work/dd.zip" "$work/dd"
chmod +x "$work/dd/DepotDownloader"
DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 "$work/dd/DepotDownloader" -app "$app" -depot "$depot" \
  -manifest "$manifest" -dir "$dir" -max-downloads 16 -qr

cat <<DONE

Done. In Steam: skate. > Properties
  Compatibility: Proton Experimental (x86_64, not arm64)
  Launch options:
    bash -c 'exec "\${@/*EAAntiCheat.GameServiceLauncher.exe/$dir/ReSkateLauncher.exe}"' -- /usr/libexec/armada/armada-game-launch %command%
Then press Play on skate.
DONE
