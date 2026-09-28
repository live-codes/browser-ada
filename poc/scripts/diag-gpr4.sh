#!/usr/bin/env bash
export LLVMBIN=/usr/lib/llvm-21/bin
export PATH=$LLVMBIN:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/usr/lib/llvm-21/lib

echo "=== tools ==="
which gnatls-16 gcc-16 gnatmake-16 gprbuild clang llvm-config-21
gnatls-16 -v 2>&1 | sed -n '1,12p'
echo "=== gprconfig detection ==="
gprconfig --batch -o /tmp/g4.cgpr 2>&1
echo "exit=$?"
grep -iE 'Driver|Toolchain_Version|Runtime_Dir' /tmp/g4.cgpr
echo "=== try a tiny gprbuild ==="
rm -rf /tmp/tinyproj && mkdir -p /tmp/tinyproj && cd /tmp/tinyproj
cat > p.gpr <<'EOF'
project P is
  for Source_Dirs use (".");
  for Object_Dir use "obj";
  for Main use ("hello.adb");
end P;
EOF
cat > hello.adb <<'EOF'
with Ada.Text_IO; use Ada.Text_IO;
procedure Hello is begin Put_Line ("native gnat16 ok"); end Hello;
EOF
gprbuild -P p.gpr 2>&1 | tail -5
./hello 2>&1
