#!/usr/bin/env bash
NM=/usr/lib/llvm-21/bin/llvm-nm
SYS=/opt/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
for lib in libunwind-legacyexcept.a libunwind-wasmexcept.a libc++abi-wasmexcept.a; do
  echo "=== $lib : all _Unwind* / Personality symbols ==="
  "$NM" "$SYS/$lib" 2>&1 | grep -iE '_Unwind|personality' | sort -u | head -40
done
