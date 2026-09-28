#!/usr/bin/env bash
INC=/opt/awp/adawebpack/lib/rts-native/adainclude
echo "total adainclude entries: $(ls "$INC" | wc -l)"
for p in a-textio text_io a-calendar a-calend a-except a-finali a-tags a-stream a-string a-numeri gnat g-souinf a-direct a-envvar a-contain; do
  printf '%-14s: %s\n' "$p" "$(ls "$INC" | grep -i "^${p}" | tr '\n' ' ')"
done
