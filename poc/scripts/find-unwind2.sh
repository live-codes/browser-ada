#!/usr/bin/env bash
NM=/usr/lib/llvm-21/bin/llvm-nm
SYS=/opt/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten
echo "=== c++abi / c++ archives present ==="
ls "$SYS" | grep -iE 'c\+\+|cxxabi|unwind'
echo "=== search all .a for CallPersonality (verbose errors suppressed) ==="
for f in "$SYS"/*.a; do
  hits=$("$NM" "$f" 2>/dev/null | grep -c "_Unwind_CallPersonality")
  if [ "$hits" != "0" ]; then echo "FOUND $hits in $(basename "$f")"; fi
done
echo "=== grep source tree for the symbol ==="
grep -rn "_Unwind_CallPersonality" /opt/emsdk/upstream/emscripten/src 2>/dev/null | head
grep -rln "_Unwind_CallPersonality" /opt/emsdk/upstream/emscripten 2>/dev/null | head
echo "=== wasm_eh_support.c full ==="
cat /opt/gnat-llvm/llvm-interface/adawebpack_src/source/rtl/c/wasm_eh_support.c
