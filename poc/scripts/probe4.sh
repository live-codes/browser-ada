#!/usr/bin/env bash
echo "=== objects under /root/awtest ==="
find /root/awtest -name '*.o' -exec sh -c 'printf "%s : " "$1"; file -b "$1"' _ {} \;

echo
echo "=== libgnat.a member types (sample) ==="
rm -rf /tmp/arm && mkdir -p /tmp/arm && cd /tmp/arm
ar x /opt/awp/adawebpack/lib/rts-native/adalib/libgnat.a a-nbnbig.o s-vaispe.o system.o a-except.o s-memory.o
file *.o

echo
echo "=== how many members are not wasm ==="
rm -rf /tmp/arm2 && mkdir -p /tmp/arm2 && cd /tmp/arm2
ar t /opt/awp/adawebpack/lib/rts-native/adalib/libgnat.a > members.txt
ar x /opt/awp/adawebpack/lib/rts-native/adalib/libgnat.a
total=$(wc -l < members.txt)
notwasm=0
for f in *.o; do
  if ! file -b "$f" | grep -q WebAssembly; then notwasm=$((notwasm+1)); echo "NON-WASM: $f -> $(file -b "$f")"; fi
done
echo "total members: $total ; non-wasm: $notwasm"
