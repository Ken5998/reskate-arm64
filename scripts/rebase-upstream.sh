#!/usr/bin/env bash
# Moves patches/ onto a newer ReSkate release: rebases them from the commit
# upstream.json pins onto TAG, writes them back to patches/ and records TAG and
# its commit in upstream.json, with the skate. build (Steam manifest) that
# release supports. A patch that no longer applies stops it with an
# error that names the patch; nothing in the repository is changed then.
#
#   scripts/rebase-upstream.sh TAG [WORKDIR]   (TAG such as v2.1.3)
set -euo pipefail

tag="$1"
repo="$(cd "$(dirname "$0")/.." && pwd)"
work="${2:-$(mktemp -d)}"
field() { python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$repo/upstream.json" "$1"; }
url="$(field repository)"
old="$(field commit)"
git_() { git -C "$work/ReSkate" -c user.name=overlay -c user.email=overlay@localhost -c advice.detachedHead=false -c core.autocrlf=false "$@"; }

rm -rf "$work/ReSkate"
git -c core.autocrlf=false clone -q --filter=blob:none --no-checkout "$url" "$work/ReSkate"
new="$(git_ rev-parse "$tag^{commit}")"
git_ checkout -q -b port "$old"
shopt -s nullglob
patches=("$repo"/patches/*.patch)
[ ${#patches[@]} -gt 0 ] && git_ am -q --keep-cr "${patches[@]}"

if ! git_ rebase -q "$new" > "$work/rebase.log" 2>&1; then
    cat "$work/rebase.log" >&2
    echo "::error::The patch \"$(git_ log -1 --format=%s REBASE_HEAD 2>/dev/null || echo '?')\" does not apply to ReSkate $tag (conflicts in: $(git_ diff --name-only --diff-filter=U | tr '\n' ' '))" >&2
    git_ rebase --abort || true
    exit 1
fi

# Keep the patch file names (git format-patch would rename them after the
# subjects), so the history of each patch stays readable.
names=("${patches[@]##*/}")
out="$work/patches"; rm -rf "$out"
git_ format-patch -q --no-numbered -o "$out" "$new..port"
made=("$out"/*.patch)
if [ ${#made[@]} -eq ${#names[@]} ]; then
    rm -f "$repo"/patches/*.patch
    for i in "${!made[@]}"; do mv "${made[$i]}" "$repo/patches/${names[$i]}"; done
else
    # A patch upstream already contains drops out of the series.
    rm -f "$repo"/patches/*.patch
    mv "$out"/*.patch "$repo/patches/"
fi
manifest="$(git_ show "$new:Engine/Game/Build/supported_build.h" 2>/dev/null | sed -n 's/.*steam_manifest_id *= *"\([0-9]*\)".*/\1/p' | head -1)"
python3 - "$repo/upstream.json" "$new" "$tag" "$manifest" <<'PY'
import json, sys
path, commit, tag, manifest = sys.argv[1:]
d = json.load(open(path))
d.update(tag=tag, commit=commit)
if manifest:
    d["steam_manifest"] = manifest
open(path, "w").write(json.dumps(d, indent=2) + "\n")
PY
cd "$repo"; n=(patches/*.patch)
echo "ReSkate $tag (${new:0:7}) with ${#n[@]} patches, skate. build $(field steam_manifest)"
