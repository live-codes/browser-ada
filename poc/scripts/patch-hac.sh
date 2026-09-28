#!/usr/bin/env bash
# Minimal HAC source fixes needed for GNAT 16 (GCC 16 frontend).
#
# GNAT 16's Ada.Containers.Vectors still carries the AI12-0400 compatibility
# overload `Append (Container, New_Item : Vector)`, which makes a two-element
# record aggregate passed to Append ambiguous.  Qualify the aggregate with the
# element type.  Idempotent.
set -e

python3 - <<'PY'
import re

files = [
    "/opt/hac/src/compile/hac_sys-parser-type_def.adb",
    "/opt/hac/src/compile/hac_sys-parser-defaults.adb",
]

# `.Append ((...))`  ->  `.Append (Default_Component'(...))`
pat = re.compile(r"(Append\s*)\(\(")
repl = r"\1(Default_Component'("

for p in files:
    s = open(p, encoding='utf-8').read()
    s2, n = pat.subn(repl, s)
    if n:
        open(p, 'w', encoding='utf-8').write(s2)
    print(f"{p}: {n} aggregate(s) qualified")
PY
