#!/usr/bin/env bash
# Checks out ReSkate at the commit in upstream.json into DIR (default
# build/ReSkate) and applies patches/*.patch on top.
#
# Usage: scripts/prepare.sh [DIR]
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
dir="${1:-$root/build/ReSkate}"
py="$(command -v python3 || command -v python)"
field() { "$py" -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$root/upstream.json" "$1"; }
repository="$(field repository)"
commit="$(field commit)"

rm -rf "$dir"
git init -q "$dir"
git -C "$dir" config core.autocrlf false
git -C "$dir" fetch -q --depth 1 "$repository" "$commit"
git -C "$dir" -c advice.detachedHead=false checkout -q FETCH_HEAD
for patch in "$root"/patches/*.patch; do
  echo "Applying $(basename "$patch")"
  git -C "$dir" apply --whitespace=nowarn "$patch"
done
