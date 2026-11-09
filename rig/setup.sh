#!/bin/bash
# TEST ONLY, never ships.
#   sh rig/setup.sh          check that rig/bin is QuestZDoom 17.3 and answers (seconds)
#   sh rig/setup.sh build    rebuild the engine from source into rig/build/rig/ (~20-40 min), then MT_RIG=rig/build/rig
# The engine is ALWAYS QuestZDoom 17.3, the commits in PINS; the launcher (engine/qz = bin/qz) refuses any other.
# Builds under rig/build/ (gitignored): build/src/qzd (emawind84/gzdoom @ QZD_REV + s_sound_log.patch),
# build/src/qzw (emawind84/questzdoom @ QZW_REV: the Android wrapper's VR input code and headers), build/rig/.
# Building needs: git, cmake, make, a C++ compiler, SDL2/EGL/GLES/OpenAL/libvpx headers.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"; B="$HERE/build"
. "$HERE/PINS"
mkdir -p "$B/src"
fetch() {	# dir url rev
  [ -d "$1/.git" ] || { git init -q "$1"; git -C "$1" remote add origin "$2"; }
  [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" = "$3" ] || { git -C "$1" fetch -q --depth 1 origin "$3"; git -C "$1" checkout -q -f FETCH_HEAD; }
}
if [ "$1" = build ]; then
  fetch "$B/src/qzd" "$QZD_REPO" "$QZD_REV"
  [ "$(git -C "$B/src/qzd" rev-parse HEAD)" = "$QZD_REV" ] || { echo "setup: engine source is not $QZD_REV" >&2; exit 3; }
  git -C "$B/src/qzd" submodule update -q --init --depth 1 2>/dev/null || true
  ( cd "$B/src/qzd" && { git apply --check "$HERE/s_sound_log.patch" 2>/dev/null && git apply "$HERE/s_sound_log.patch"; } || true )
  fetch "$B/src/qzw" "$QZW_REPO" "$QZW_REV"
  git -C "$B/src/qzw" fetch -q --depth 1 origin "$QZW_REV" 2>/dev/null || true
  mkdir -p "$B/rig"; cp -a "$HERE/engine/." "$B/rig/"; cp "$HERE/PINS" "$B/rig/PINS"
  QGZ="$B/src/qzd" JNI="$B/src/qzw/Projects/Android/jni" bash "$B/rig/build.sh"
  [ -x "$B/rig/qzdoom" ] && { cp "$HERE/engine/qz" "$B/rig/qz"; cp "$HERE/PINS" "$B/rig/PINS"; }
  RIG="${MT_RIG:-$B/rig}"
else
  RIG="${MT_RIG:-$HERE/bin}"
fi
[ -x "$RIG/qzdoom" ] && [ -x "$RIG/qz" ] || { echo "setup: no engine at $RIG (rig/bin from git, or: sh rig/setup.sh build)" >&2; exit 3; }
mkdir -p "$HERE/runs"
timeout 120 "$RIG/qz" -norun >/dev/null 2>"$HERE/runs/engine_check.txt" || true
grep -q 'qz: engine OK' "$HERE/runs/engine_check.txt" || { cat "$HERE/runs/engine_check.txt" >&2; echo "setup: the rig at $RIG is not QuestZDoom 17.3" >&2; exit 3; }
echo "rig ready: $RIG/qz ($(grep 'qz: engine OK' "$HERE/runs/engine_check.txt" | cut -c15-))"
