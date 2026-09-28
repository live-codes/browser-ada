#!/usr/bin/env bash
export PATH=/opt/awp/adawebpack/bin:/usr/bin:/bin
cd /root/awtest
RTS=/opt/awp/adawebpack/lib/rts-native/adalib
AWP=/opt/awp/adawebpack/lib/adawebpack

echo "=== variant A: gcc driver, no --target ==="
rm -f A.wasm
llvm-gcc main.o b__main.o .objs/demo.o -nostdlib \
  -Wl,--export-all -Wl,--allow-undefined -Wl,--no-entry \
  -L.objs -L$AWP -L$RTS -static-libgcc $RTS/libgnat.a -o A.wasm 2>&1 | tail -8
file A.wasm 2>&1

echo "=== variant B: direct wasm-ld ==="
rm -f B.wasm
wasm-ld --export-all --allow-undefined --no-entry \
  --error-limit=0 \
  -L.objs -L$AWP -L$RTS \
  -o B.wasm main.o b__main.o .objs/demo.o $RTS/libgnat.a 2>&1 | tail -20
file B.wasm 2>&1
ls -l A.wasm B.wasm 2>&1
