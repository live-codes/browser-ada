#!/usr/bin/env bash
NM=/usr/lib/llvm-21/bin/llvm-nm
SYS=/opt/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
echo "=== members of libunwind-wasmexcept.a ==="
ar t "$SYS/libunwind-wasmexcept.a"
echo "=== strings grep ==="
strings "$SYS/libunwind-wasmexcept.a" | grep -i "CallPersonality" | head
echo "=== nm full (all symbols) ==="
"$NM" "$SYS/libunwind-wasmexcept.a" 2>&1 | sort -u
echo "=== __wasm_lpad_context anywhere? ==="
for lib in libunwind-wasmexcept.a libunwind-legacyexcept.a libc++abi-wasmexcept.a; do
  echo "-- $lib"; "$NM" "$SYS/$lib" 2>/dev/null | grep -i lpad
done
