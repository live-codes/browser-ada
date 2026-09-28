#!/usr/bin/env bash
G=/opt/gnat-llvm/llvm-interface/gnat_src/libgnat
echo "=== s-expont / s-exponn / s-exponr in gnat source ==="
ls -l "$G"/s-expont.* "$G"/s-exponn.* "$G"/s-exponr.* 2>&1
echo "=== head of s-expont.ads ==="
head -40 "$G/s-expont.ads" 2>/dev/null | tail -15
echo "=== EMCC_LIBGNAT_UNITS definition ==="
grep -n -A12 "^EMCC_LIBGNAT_UNITS = " /opt/gnat-llvm/llvm-interface/adawebpack_src/source/rtl/Makefile.target
echo "=== EMCC_LIBGNAT_SPEC_UNITS ==="
grep -n "EMCC_LIBGNAT_SPEC_UNITS" /opt/gnat-llvm/llvm-interface/adawebpack_src/source/rtl/Makefile.target
echo "=== does RTS have s-expont? ==="
ls /opt/gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm-emcc-eh/adainclude/ | grep -E 'expont|exponn|exponr' || echo none
