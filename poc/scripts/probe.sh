#!/usr/bin/env bash
export PATH=/opt/awp/adawebpack/bin:/usr/bin:/bin
echo "--- llvm-gcc --target=wasm32 --version ---"
llvm-gcc --target=wasm32 --version 2>&1 | tail -3
echo "--- llvm-gcc -target wasm32 --version ---"
llvm-gcc -target wasm32 --version 2>&1 | tail -3
echo "--- dumpmachine ---"
llvm-gcc -dumpmachine 2>&1
echo "--- print-prog-name ld ---"
llvm-gcc -print-prog-name=ld 2>&1
echo "--- print-prog-name wasm-ld ---"
llvm-gcc -print-prog-name=wasm-ld 2>&1
echo "--- link with -target wasm32 ---"
cd /root/awtest
rm -f main2.wasm
llvm-gcc main.o b__main.o .objs/demo.o -target wasm32 -nostdlib \
  -Wl,--export-all -Wl,--allow-undefined -Wl,--no-entry \
  -L.objs -L/opt/awp/adawebpack/lib/adawebpack/ \
  -L/opt/awp/adawebpack/lib/rts-native/adalib/ -static-libgcc \
  /opt/awp/adawebpack/lib/rts-native/adalib/libgnat.a -o main2.wasm 2>&1 | tail -20
echo "--- result ---"
ls -l main2.wasm 2>&1
file main2.wasm 2>&1
