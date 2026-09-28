#!/usr/bin/env bash
set -o pipefail
export PATH=/opt/gnat-llvm/llvm-interface/bin:/usr/lib/llvm-21/bin:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/usr/lib/llvm-21/lib
RTS=/opt/gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm-emcc-eh
G=/opt/gnat-llvm/llvm-interface/gnat_src/libgnat
CC=/opt/gnat-llvm/llvm-interface/bin/llvm-gcc

cp -f "$G"/s-expont.ads "$G"/s-expont.adb "$G"/s-explli.ads "$G"/s-explli.adb "$RTS/adainclude/"

cd "$RTS/adalib"
COMPILE="$CC -c -gnatpg -nostdinc -I../adainclude --target=wasm32 -gnateT=../target.atp"

echo ">>> s-expont.adb (generic body)"
$COMPILE ../adainclude/s-expont.adb || exit 1
echo ">>> s-explli.adb (No_Body; compiles the instantiation spec)"
$COMPILE ../adainclude/s-explli.adb || exit 1

chmod a-wx s-expont.ali s-explli.ali 2>/dev/null
objs=""
for o in s-expont.o s-explli.o; do [ -s "$o" ] && objs="$objs $o"; done
echo "adding objects:$objs"
ar r libgnat.a $objs
/usr/lib/llvm-21/bin/llvm-ranlib libgnat.a
ls -l s-expont.ali s-explli.ali 2>&1
echo DONE add-explli
