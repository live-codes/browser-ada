#!/usr/bin/env bash
export PATH=/opt/awp/adawebpack/bin:/usr/bin:/bin
mkdir -p /root/probe2 && cd /root/probe2
printf 'procedure T is begin null; end T;\n' > t.adb

echo "=== raw compile WITHOUT --target ==="
llvm-gcc -c t.adb -o t_native.o 2>&1 | tail -5
file t_native.o 2>&1

echo "=== raw compile WITH --target=wasm32 ==="
llvm-gcc -c --target=wasm32 t.adb -o t_wasm.o 2>&1 | tail -5
file t_wasm.o 2>&1

echo "=== does plain gcc accept --target ? ==="
llvm-gcc -c --target=wasm32 t.adb -o t_wasm2.o 2>&1 | tail -5

echo "=== capture gprbuild verbose link/compile cmd ==="
cd /root/awtest
export GPR_CONFIG=/opt/awp/adawebpack/share/gprconfig
gprbuild -p -P test.gpr -v 2>&1 | grep -E "llvm-gcc|llvm-gnat1|link" | head -20
