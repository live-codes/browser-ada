#!/usr/bin/env bash
AWP=/opt/gnat-llvm/llvm-interface/adawebpack_src
RTS=/opt/gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm-emcc-eh
NM=/usr/lib/llvm-21/bin/llvm-nm

echo "=== _Unwind_CallPersonality in raise-gcc.c ==="
grep -n "_Unwind_CallPersonality\|CallPersonality\|wasm_throw\|__builtin_wasm" "$AWP/source/rtl/../../gnat_src/raise-gcc.c" 2>/dev/null | head
echo "--- in gnat_src/raise-gcc.c (patched) ---"
grep -n "_Unwind_CallPersonality\|CallPersonality\|__builtin_wasm\|wasm" /opt/gnat-llvm/llvm-interface/gnat_src/raise-gcc.c | head -30

echo "=== wasm_eh_support.c ==="
grep -n "_Unwind\|CallPersonality\|wasm" "$AWP/source/rtl/c/wasm_eh_support.c" | head -40

echo "=== the GCC patch (what it changes in raise-gcc.c) ==="
sed -n '1,120p' /opt/gnat-llvm/llvm-interface/patches/gcc-16-wasm-eh-raise-gcc.patch

echo "=== libgnat.a _Unwind symbols ==="
cd /tmp && rm -rf nmx && mkdir nmx && cd nmx
ar x "$RTS/adalib/libgnat.a" raise-gcc.o wasm_eh_support.o 2>/dev/null
$NM raise-gcc.o 2>/dev/null | grep -i unwind | head
$NM wasm_eh_support.o 2>/dev/null | grep -i unwind | head

echo "=== emscripten libunwind has CallPersonality? ==="
find /opt/emsdk/upstream -name 'libunwind*.a' 2>/dev/null | head
