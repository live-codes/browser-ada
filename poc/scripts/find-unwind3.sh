#!/usr/bin/env bash
NM=/usr/lib/llvm-21/bin/llvm-nm
SYS=/opt/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
for lib in libc++abi-wasmexcept.a libc++abi-legacyexcept.a libc++abi.a libc++-wasmexcept.a; do
  echo "=== $lib (Personality symbols) ==="
  "$NM" "$SYS/$lib" 2>&1 | grep -iE 'personality|CallPersonality' | head
done
echo "=== system_libs.py context ==="
grep -n -B3 -A3 "CallPersonality" /opt/emsdk/upstream/emscripten/tools/system_libs.py | head -40
