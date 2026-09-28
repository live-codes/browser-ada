#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq software-properties-common
add-apt-repository -y ppa:ubuntu-toolchain-r/test
apt-get update -qq
echo "=== candidates ==="
for p in gcc-16 g++-16 gnat-16 gcc-15 gnat-15; do
  printf '%-10s: %s\n' "$p" "$(apt-cache policy "$p" 2>/dev/null | grep Candidate)"
done
echo "=== installing gcc-16 gnat-16 (if available) ==="
if apt-cache policy gnat-16 2>/dev/null | grep -q 'Candidate: [0-9]'; then
  apt-get install -y gcc-16 g++-16 gnat-16
  echo "--- versions ---"
  gcc-16 --version | head -1
  gnatls-16 --version 2>/dev/null | head -1 || ls -l /usr/bin/*gnatls* 2>&1
  ls /usr/lib/gcc/x86_64-linux-gnu/16/adalib 2>&1 | head -3
else
  echo "gnat-16 not available from PPA"
fi
echo DONE
