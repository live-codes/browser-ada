#!/usr/bin/env bash
echo "=== /usr/share/gprconfig ==="
ls /usr/share/gprconfig
echo "=== gnat-related xml ==="
grep -l -i gnat /usr/share/gprconfig/*.xml 2>/dev/null
echo "=== gnat.xml (if present) ==="
for f in /usr/share/gprconfig/*gnat*.xml; do echo "----- $f"; cat "$f"; done 2>/dev/null | head -80
echo "=== full generated config /tmp/g.cgpr ==="
cat /tmp/g.cgpr
echo "=== system gnat? ==="
ls -l /usr/bin/gnatls /usr/bin/gnatgcc /usr/bin/gnat 2>&1
dpkg -l | grep -E '^ii +(gnat|gcc-13|gnat-13)' | awk '{print $2, $3}'
