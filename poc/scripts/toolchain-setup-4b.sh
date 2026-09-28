#!/usr/bin/env bash
# Stage 4b: build the EH-enabled Emscripten wasm runtime (rts-wasm-emcc-eh).
set -o pipefail
export EMSDK=/opt/emsdk
export LLVMBIN=/usr/lib/llvm-21/bin
export PATH=$EMSDK/upstream/emscripten:$EMSDK/node/24.19.0_64bit/bin:$LLVMBIN:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/usr/lib/llvm-21/lib
export EMCC=$EMSDK/upstream/emscripten/emcc
unset GNAT_WASM_EH

cd /opt/gnat-llvm/llvm-interface
echo "=== make wasm-emcc-eh ==="
make wasm-emcc-eh PROCS=6 LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=clang-cpp \
  GNATMAKE=gnatmake-16 EMCC="$EMCC" 2>&1 | tee /tmp/rts-eh-build.log
echo "MAKE_EXIT=${PIPESTATUS[0]}"
echo "=== runtime tree ==="
ls -l lib/gnat-llvm/wasm32/ 2>&1
ls lib/gnat-llvm/wasm32/rts-wasm-emcc-eh/ 2>&1
ls -l lib/gnat-llvm/wasm32/rts-wasm-emcc-eh/adalib/libgnat.a 2>&1
echo "--- key RTS units (exceptions/textio/calendar/containers) ---"
ls lib/gnat-llvm/wasm32/rts-wasm-emcc-eh/adainclude/ | grep -E 'a-except|a-exexpr|a-elchha|a-textio|a-calend|a-conhel|a-exctra' | head
echo "DONE stage4b"
