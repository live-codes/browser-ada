#!/usr/bin/env bash
NM=/usr/lib/llvm-21/bin/llvm-nm
SYS=/opt/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
for f in "$SYS"/*.a; do
  if "$NM" "$f" 2>/dev/null | grep -q "_Unwind_CallPersonality"; then
    echo "FOUND in $(basename "$f")"
  fi
done
