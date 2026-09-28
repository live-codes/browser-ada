#!/usr/bin/env bash
RTS=/opt/gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm-emcc-eh
G=/opt/gnat-llvm/llvm-interface/gnat_src/libgnat
echo "=== RTS has these exp* ==="
ls "$RTS/adainclude" | grep -E 'exp' | sort
echo "=== gnat source s-explli ==="
ls -l "$G"/s-explli.* 2>&1
echo "--- s-explli.ads ---"
cat "$G/s-explli.ads" 2>/dev/null | head -60
echo "=== s-explli referenced anywhere in Makefile.target? ==="
grep -n "explli" /opt/gnat-llvm/llvm-interface/adawebpack_src/source/rtl/Makefile.target || echo "(not listed)"
echo "=== what does HAC use? ==="
grep -n "Exp_Lli\|Exp_LLI\|s-explli" /opt/hac/src/compile/hac_sys-pcode-interpreter-operators.adb | head
