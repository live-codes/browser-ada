#!/usr/bin/env bash
# Build HAC (Ada compiler) to wasm with the EH-enabled GNAT-LLVM toolchain.
set -o pipefail
export EMSDK=/opt/emsdk
export LLVMBIN=/usr/lib/llvm-21/bin
export PATH=/opt/gnat-llvm/llvm-interface/bin:$LLVMBIN:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/usr/lib/llvm-21/lib
export EMCC=/opt/emsdk/upstream/emscripten/emcc
RTS=/opt/gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm-emcc-eh

# --- HAC sources (pinned) ---------------------------------------------------
if [ ! -d /opt/hac/src ]; then
  cp -r /mnt/c/Users/hatem/AppData/Local/Temp/opencode/hac /opt/hac
fi

# --- HAC source fixes for GNAT 16 ------------------------------------------
bash /mnt/d/DevWork/live-codes/browser-ada/poc/scripts/patch-hac.sh

# --- gprconfig llvm target + driver wrapper --------------------------------
cp -f /opt/gnat-llvm/llvm-interface/adawebpack_src/packages/Fedora/llvm.xml /usr/share/gprconfig/llvm.xml
ln -sfn rts-wasm-emcc-eh /opt/gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm
BIN=/opt/gnat-llvm/llvm-interface/bin
printf '#!/bin/sh\nexec "%s/llvm-gcc" "$@"\n' "$BIN" > "$BIN/llvm-gcc-16"
chmod +x "$BIN/llvm-gcc-16"

# --- project sources --------------------------------------------------------
SRC=/mnt/d/DevWork/live-codes/browser-ada/poc/hac-wasm
DEST=/root/hacwasm
rm -rf "$DEST" && mkdir -p "$DEST"
cp "$SRC"/main.adb "$SRC"/hac_runner.ads "$SRC"/hac_runner.adb "$SRC"/hac_wasm.gpr "$DEST"/
cp /mnt/d/DevWork/live-codes/browser-ada/poc/eh-smoke/unwind_callpersonality.c "$DEST"/
cp /mnt/d/DevWork/live-codes/browser-ada/poc/eh-smoke/ada_runtime_support.js "$DEST"/
cd "$DEST"

echo "=== compile unwind_callpersonality.c ==="
"$EMCC" -c -O2 -fwasm-exceptions unwind_callpersonality.c -o unwind_callpersonality.o

echo "=== gprbuild HAC (compile + bind) ==="
gprbuild --target=llvm --RTS="$RTS" -c -b -p -P hac_wasm.gpr 2>&1 | tail -60
GPR=${PIPESTATUS[0]}
echo "GPR_EXIT=$GPR"
if [ "$GPR" != "0" ]; then echo "COMPILE FAILED"; exit "$GPR"; fi

echo "=== link with emcc ==="
"$EMCC" -fwasm-exceptions -O2 \
  -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=16777216 \
  -sMODULARIZE=1 -sEXPORT_ES6=1 -sEXPORT_NAME=createHacModule \
  -sINVOKE_RUN=0 -sEXIT_RUNTIME=0 -sERROR_ON_UNDEFINED_SYMBOLS=0 \
  -sFORCE_FILESYSTEM=1 -sEXPORTED_RUNTIME_METHODS=FS,ccall \
  -sEXPORTED_FUNCTIONS=_main,_hac_run \
  --js-library ada_runtime_support.js \
  unwind_callpersonality.o .objs/*.o \
  "$RTS/adalib/libgnat.a" \
  -o hac.js 2>&1 | tail -30
echo "EMCC_EXIT=${PIPESTATUS[0]}"
ls -l hac.js hac.wasm 2>&1
cp -f hac.js hac.wasm "$SRC"/ 2>&1

echo "=== link standalone (single-file, classic script, for file:// use) ==="
"$EMCC" -fwasm-exceptions -O2 \
  -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=16777216 \
  -sMODULARIZE=1 -sEXPORT_NAME=createHacModule -sSINGLE_FILE=1 \
  -sINVOKE_RUN=0 -sEXIT_RUNTIME=0 -sERROR_ON_UNDEFINED_SYMBOLS=0 \
  -sFORCE_FILESYSTEM=1 -sEXPORTED_RUNTIME_METHODS=FS,ccall \
  -sEXPORTED_FUNCTIONS=_main,_hac_run \
  --js-library ada_runtime_support.js \
  unwind_callpersonality.o .objs/*.o \
  "$RTS/adalib/libgnat.a" \
  -o hac-standalone.js 2>&1 | tail -5
echo "STANDALONE_EXIT=${PIPESTATUS[0]}"
ls -l hac-standalone.js 2>&1
cp -f hac-standalone.js "$SRC"/ 2>&1
echo "DONE build-hac"
