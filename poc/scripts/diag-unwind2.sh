#!/usr/bin/env bash
NM=/usr/lib/llvm-21/bin/llvm-nm
SYS=/opt/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
for lib in libunwind-legacyexcept.a libunwind-wasmexcept.a libunwind.a libunwind-noexcept.a; do
  if [ -f "$SYS/$lib" ]; then
    echo "=== $lib ==="
    $NM "$SYS/$lib" 2>/dev/null | grep -iE 'CallPersonality|_Unwind_RaiseException|_Unwind_GetIP\b' | head
  fi
done
echo "=== default emcc exception encoding ==="
/opt/emsdk/upstream/emscripten/emcc -dM -E -x c /dev/null -fwasm-exceptions 2>/dev/null | grep -iE 'wasm.*exception|legacy' | head
echo "=== emcc settings for legacy ==="
grep -rn "WASM_LEGACY_EXCEPTIONS" /opt/emsdk/upstream/emscripten/src/settings.js | head -3
