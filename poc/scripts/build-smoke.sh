#!/usr/bin/env bash
# Build an Ada -> wasm module with the prebuilt AdaWebPack (GNAT-LLVM) toolchain.
#
# Notes:
#  * gprconfig wants version-suffixed drivers (llvm-gcc-14); we create wrapper
#    scripts (symlinks don't work because GNAT drivers dispatch on argv[0]).
#  * The GCC-14 link driver rejects `--target=wasm32`, so we let gprbuild
#    compile+bind (its link step fails) and link with wasm-ld ourselves.

set -u

AWP=/opt/awp/adawebpack
export PATH=$AWP/bin:/usr/bin:/bin
export GPR_CONFIG=$AWP/share/gprconfig

# --- version-suffixed driver wrappers ---------------------------------------
cd "$AWP/bin"
for t in gcc gnat1 gnatbind gnatls gnatmake gnatlink gnatkr gnatchop gnatprep gnatclean gnatname; do
  if [ -e "llvm-$t" ]; then
    printf '#!/bin/sh\nexec "%s" "$@"\n' "$AWP/bin/llvm-$t" > "llvm-$t-14"
    chmod +x "llvm-$t-14"
  fi
done

# --- sync sources -----------------------------------------------------------
SRC=/mnt/d/DevWork/live-codes/browser-ada/poc/adawebpack-smoke
DEST=/root/awtest
rm -rf "$DEST"
mkdir -p "$DEST"
cp "$SRC"/demo.ads "$SRC"/demo.adb "$SRC"/main.adb "$SRC"/test.gpr "$DEST"/

# --- compile + bind (link step will fail; that is expected) -----------------
cd "$DEST"
gprbuild -p -P test.gpr || true

# --- link with wasm-ld ------------------------------------------------------
cd "$DEST/.objs"
RTS=$AWP/lib/rts-native/adalib
wasm-ld --export-all --allow-undefined --no-entry \
  -o "$DEST/main.wasm" \
  main.o b__main.o demo.o \
  "$RTS/libgnat.a"

echo "LINK_OK"
file "$DEST/main.wasm"
ls -l "$DEST/main.wasm"

# --- publish artifact -------------------------------------------------------
cp "$DEST/main.wasm" "$SRC/main.wasm"
echo "copied main.wasm to $SRC"
