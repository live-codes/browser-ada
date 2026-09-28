#!/usr/bin/env bash
set -o pipefail
export EMSDK=/opt/emsdk
export LLVMBIN=/usr/lib/llvm-21/bin
export PATH=/opt/gnat-llvm/llvm-interface/bin:$LLVMBIN:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/usr/lib/llvm-21/lib

AWP=/opt/gnat-llvm/llvm-interface/adawebpack_src
RTS=/opt/gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm-emcc-eh

# Make gprconfig aware of the "llvm" target (GNAT_LLVM) and give it a default
# runtime directory that exists.
cp -f "$AWP/packages/Fedora/llvm.xml" /usr/share/gprconfig/llvm.xml
ln -sfn rts-wasm-emcc-eh /opt/gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm

# gprconfig derives the driver name as llvm-gcc-<gcc_version>; GNAT drivers
# dispatch on argv[0], so provide a wrapper that execs the real driver.
BIN=/opt/gnat-llvm/llvm-interface/bin
printf '#!/bin/sh\nexec "%s/llvm-gcc" "$@"\n' "$BIN" > "$BIN/llvm-gcc-16"
chmod +x "$BIN/llvm-gcc-16"

SRC=/mnt/d/DevWork/live-codes/browser-ada/poc/eh-smoke
DEST=/root/ehsmoke
rm -rf "$DEST" && mkdir -p "$DEST"
cp "$SRC"/demo.ads "$SRC"/demo.adb "$SRC"/main.adb "$SRC"/test.gpr "$SRC"/ada_runtime_support.js "$SRC"/unwind_callpersonality.c "$DEST"/
cd "$DEST"

echo "=== compile unwind_callpersonality.c (emcc) ==="
/opt/emsdk/upstream/emscripten/emcc -c -O2 -fwasm-exceptions unwind_callpersonality.c -o unwind_callpersonality.o

echo "=== gprbuild (compile + bind) ==="
gprbuild --target=llvm --RTS="$RTS" -c -b -p -P test.gpr 2>&1 | tail -30
echo "GPR_EXIT=${PIPESTATUS[0]}"

echo "=== object symbols of interest ==="
NM=$LLVMBIN/llvm-nm
for o in .objs/main.o .objs/b__main.o; do
  echo "--- $o"
  $NM "$o" 2>/dev/null | grep -iE 'adainit|ada_main|gnat_initialize| T main|ada_add|ada_try' | head
done

echo "=== link with emcc ==="
/opt/emsdk/upstream/emscripten/emcc -fwasm-exceptions -O2 \
  -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=8388608 \
  -sMODULARIZE=1 -sEXPORT_ES6=1 -sEXPORT_NAME=createAdaModule \
  -sINVOKE_RUN=0 -sEXIT_RUNTIME=0 -sERROR_ON_UNDEFINED_SYMBOLS=0 \
  -sEXPORTED_FUNCTIONS=_main,_ada_add,_ada_fib,_ada_try_raise \
  --js-library ada_runtime_support.js \
  .objs/main.o .objs/b__main.o .objs/demo.o unwind_callpersonality.o \
  "$RTS/adalib/libgnat.a" \
  -o ada.js 2>&1 | tail -30
echo "EMCC_EXIT=${PIPESTATUS[0]}"

ls -l ada.js ada.wasm 2>&1
cp -f ada.js ada.wasm "$SRC"/ 2>&1
echo "DONE build-eh-smoke"
