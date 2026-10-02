# FINDINGS — Running Ada in the browser with HAC compiled to WebAssembly

Technical reference for the `browser-ada` proof of concept: how an Ada compiler
(HAC) was built for `wasm32`, what it depends on, how the toolchain was
assembled, and how to rebuild or update it.

This document is deliberately verbose: it records the exact versions, commits,
commands, workarounds and failure modes encountered, so the build can be
reproduced and upgraded.

---

## 1. Goal and result

**Goal.** Compile and run arbitrary Ada source in the browser, fully
client-side, with no server-side compilation.

**Result.** Working. `poc/hac-wasm/index.html` is a self-contained page that
compiles and runs typed-in Ada using **HAC** (an Ada-subset compiler and p-code
interpreter written in Ada) compiled to WebAssembly. Verified: hello world,
loops, recursion, nested subprograms, and Ada exception propagation.

The pipeline is:

```
Ada source (typed in browser)
        │
        ▼
HAC compiler+VM (hac.wasm)          ← compiled from Ada to wasm by GNAT-LLVM
   • lexer/parser/semantics
   • emits HAC p-code
   • p-code interpreter runs it
        │
        ▼
Ada.Text_IO → Emscripten stdout → JS `print` callback → page output
```

Nothing runs on a server. The compiler, the runtime and the user program all
execute inside the WebAssembly module in the page.

---

## 2. Why HAC

There is no released Ada-to-WebAssembly compiler that can compile arbitrary Ada
at runtime. The only realistic route to "type Ada, run it in the browser" is to
compile an existing Ada compiler to wasm. **HAC** is ideal:

- Small, single-pass Ada-subset compiler **plus** a p-code virtual machine, all
  written in Ada (MIT licensed).
- Designed to be embedded; can compile from an in-memory stream.
- Output goes through `Ada.Text_IO`, which maps cleanly onto Emscripten's stdout.

Alternatives considered and rejected: GNAT itself is far too large and depends
on a full toolchain at runtime; the AdaCore "WIT toolchain" intern project only
compiles pre-declared exports, not arbitrary code.

---

## 3. The hard requirement: exception propagation

HAC's control flow is exception-based end to end (parser error recovery, VM
bounds/`End_Error` handling, tasking). It also needs `Ada.Text_IO`,
`Ada.Calendar`, `Ada.Containers` and `Ada.Directories`.

The **official prebuilt AdaWebPack release (24.0.0)** is unusable for HAC:

- Its runtime is a **no-exception-propagation** runtime
  (`a-elchha__wasm.adb` is literally "the default last chance handler for no
  propagation runtimes"; the compiler removes handlers at compile time). A
  `raise` traps immediately.
- It ships no `Ada.Text_IO`, `Ada.Calendar`, `Ada.Containers`, `GNAT.*`.

Therefore a **full EH-enabled toolchain** had to be built from source. The
public recipe for this is the `ovenpasta` forks of `gnat-llvm` and
`adawebpack`, which add native WebAssembly exception handling (GCC 16 front end
+ LLVM 21 + Emscripten). The runtime produced is `rts-wasm-emcc-eh`.

---

## 4. Components and third-party dependencies

| Component | Version / commit | Role | License | Link |
|---|---|---|---|---|
| **HAC** | 0.45 (10-Aug-2026), commit `8710a2c2608fed51e409f954838b82e0b6107e0c` | Ada-subset compiler + p-code VM; the thing compiled to wasm | MIT | <https://github.com/zertovitch/hac> |
| **GNAT-LLVM** (fork) | commit `28139a8b9d73bd62522c686cc27f5c26b5fb8811` (2026-06-30) | Ada → LLVM → wasm32 compiler | GPL-3.0-or-later (`COPYING3`); runtime under GCC RLE | <https://github.com/ovenpasta/gnat-llvm> (upstream <https://github.com/AdaCore/gnat-llvm>) |
| **GCC 16.1.0 sources** | tag `releases/gcc-16.1.0`, commit `6afcc4f6da931eb93f3ab001a0dd9650ea71d1ea` | GNAT front-end sources used by GNAT-LLVM | GPL-3.0-or-later with GCC RLE | <https://gcc.gnu.org/git/gcc.git> |
| **AdaWebPack** (fork) | commit `1ff162b88762113b884d250a43aed85aba8e7c02` | WASM RTS overrides, Web API bindings, JS glue | BSD-3-Clause (bindings) + GPL-3.0 with GCC RLE (runtime) | <https://github.com/ovenpasta/adawebpack> (upstream <https://github.com/godunko/adawebpack>) |
| **bb-runtimes** (fork) | branch `gnat-fsf-15`, commit `1b0f15a9485e1673ef9acc479e27fd89ae5fc3c2` | bare-board runtime sources (math, memory) | GPL-3.0 with GCC RLE | <https://github.com/ovenpasta/bb-runtimes> |
| **llvm-bindings** | commit `06933d37bf2eb1b363dfe3cff9a48fe0cc3e4e20` | Ada bindings to LLVM (build-time only) | GPL-3.0 (`COPYING3`) | <https://github.com/AdaCore/llvm-bindings> |
| **LLVM / Clang / lld** | 21.1.8 | wasm backend, `wasm-ld`, build-time libs | Apache-2.0 WITH LLVM-exception | <https://llvm.org> |
| **Emscripten** | 6.0.10 (`d6c521a7f05449857c76bd99e396895583cf2083`) | links the EH wasm; provides libc/JS runtime glue | MIT / University of Illinois NCSA | <https://emscripten.org> |
| **gprbuild** | 2024.1.20231009 (Ubuntu 24.04) | Ada project build tool | GPL-3.0 (GNAT tooling) | <https://github.com/AdaCore/gprbuild> |
| **Alire** | 2.1.1 | GNAT toolchain manager (see §6.1 note) | GPL-3.0 | <https://alire.ada.dev> |
| **Host GCC/GNAT 16** | 16.0.1 20260315 (`ppa:ubuntu-toolchain-r/test`) | native Ada compiler used to **build** GNAT-LLVM | GPL-3.0 with GCC RLE | <https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test> |
| `poc/eh-smoke/unwind_callpersonality.c` | in-repo | `_Unwind_CallPersonality` shim missing from Emscripten 6.0.10 libunwind | Apache-2.0 WITH LLVM-exception (adapted from LLVM libunwind via AdaWebPack `wasm_eh_unwind.c`) | — |

### Licensing note for redistribution

The **compiler toolchain** (GNAT-LLVM, GCC, gnat runtime, bb-runtimes) is
GPL-3.0-or-later **with the GCC Runtime Library Exception**. The exception
permits distributing binaries produced by the compiler without imposing GPL on
the compiled program. The **AdaWebPack runtime** is likewise GPL-3.0 with the
GCC RLE; its **Web API bindings** are BSD-3-Clause. HAC itself is MIT.

For a LiveCodes integration, the resulting `hac.wasm` is a compiled program;
keep the license/attribution notices and verify the runtime exception applies
to your distribution model.

---

## 5. Toolchain layout (inside WSL)

Everything is built inside the WSL distro `racket-build` (Ubuntu 24.04), as
root. Nothing is installed on the Windows side.

```
/opt/gnat-llvm/                                  # GNAT-LLVM checkout (fork)
  llvm-interface/
    gcc/                                         # GCC 16.1.0 sources (patched)
    gnat_src -> gcc/gcc/ada                      # GNAT front-end sources
    rts-sources -> bb-runtimes/.../rts-sources/  # extra RTS sources
    bb-runtimes/                                 # fork, branch gnat-fsf-15
    adawebpack_src/                              # fork (RTS overrides + bindings)
    llvm-bindings/ -> ../llvm-bindings           # at /opt/gnat-llvm/llvm-bindings
    Makefile.target -> adawebpack_src/source/rtl/Makefile.target
    bin/llvm-gcc, llvm-gnat1, llvm-gnatbind, ... # built compiler
    lib/gnat-llvm/wasm32/rts-wasm-emcc-eh/       # the EH wasm runtime
      adainclude/                                # ~200 Ada sources
      adalib/libgnat.a                           # ~1.5 MB static wasm runtime
      target.atp, ada_source_path, ada_object_path
/opt/emsdk/                                      # Emscripten 6.0.10
/opt/hac/                                        # HAC sources (patched)
/opt/gnat-llvm/.../bin/llvm-gcc-16               # wrapper (see gotcha G2)
```

---

## 6. Build process

All steps are scripted under `poc/scripts/`. Run them in order from a WSL shell
(`wsl -d racket-build -- bash /mnt/d/.../poc/scripts/<script>.sh`). They are
idempotent enough to re-run.

> **Note on `$` expansion.** Invoke scripts by path. Do **not** paste shell
> snippets containing `$VAR` through the Windows→WSL command line; PowerShell
> expands them first. Script files avoid this.

### 6.0 Prerequisites

- Windows with WSL2 and an Ubuntu 24.04 distro (`racket-build` here).
- ~4 GB free disk for sources + LLVM; a few GB more for GCC/Emscripten.
- Network access. 12 cores / 8 GB RAM was sufficient (compiler build capped at
  `PROCS=6` to avoid OOM).

### 6.1 Base packages, Alire, LLVM/Clang 21 — `toolchain-setup-1.sh`

- `apt-get install` base tools.
- Install **Alire 2.1.1** and `alr toolchain --select gnat_native=16.1.0`.
  - **Caveat:** this Alire GNAT is *not usable* by `gprconfig` (see gotcha G1).
    It is harmless to have installed, but the build uses the distro compiler
    from §6.2.
- Add the LLVM apt repo and install **LLVM/Clang/lld 21.1.8**
  (`clang-21`, `llvm-21-dev`, `libclang-21-dev`, `lld-21`, ...).

### 6.2 Distro GCC/GNAT 16 — `toolchain-setup-1b.sh`

Ubuntu 24.04 ships only GCC 13, and its `gprconfig` knowledge base hardcodes
`/usr/lib/gcc/...`. Install the distro **`gcc-16`, `g++-16`, `gnat-16`** from
`ppa:ubuntu-toolchain-r/test` (16.0.1). This makes `gprconfig` detect Ada
natively. Also create target-prefixed symlinks so `gprbind` can find the binder:

```bash
ln -sf /usr/bin/gnatbind-16 /usr/local/bin/x86_64-linux-gnu-gnatbind
ln -sf /usr/bin/gnatlink-16 /usr/local/bin/x86_64-linux-gnu-gnatlink
ln -sf /usr/bin/gcc-16     /usr/local/bin/x86_64-linux-gnu-gcc
ln -sf /usr/bin/g++-16     /usr/local/bin/x86_64-linux-gnu-g++
```

### 6.3 Fetch sources and patch — `toolchain-setup-2.sh`, `2b.sh`

```bash
git clone --depth 1 https://github.com/ovenpasta/gnat-llvm.git /opt/gnat-llvm
cd /opt/gnat-llvm
git clone --depth 1 https://github.com/AdaCore/llvm-bindings.git llvm-bindings
cd llvm-interface
git clone --branch releases/gcc-16.1.0 --depth 1 \
    https://github.com/gcc-mirror/gcc.git gcc
git clone --depth 1 https://github.com/ovenpasta/adawebpack.git adawebpack_src
git clone -b gnat-fsf-15 --depth 1 \
    https://github.com/ovenpasta/bb-runtimes.git bb-runtimes

# GCC patches (Repinfo accessors + wasm EH personality)
for p in gcc-16-repinfo-accessors gcc-16-allow-reraise-no-propagation \
         gcc-16-wasm-eh-raise-gcc; do
  git -C gcc apply "$PWD/patches/$p.patch"
done

ln -sfn "$PWD/gcc/gcc/ada" gnat_src
ln -sfn "$PWD/bb-runtimes/gnat_rts_sources/include/rts-sources/" rts-sources
ln -sfn "$PWD/adawebpack_src/source/rtl/Makefile.target" Makefile.target
```

`2b.sh` exists because `git -C gcc apply patches/...` resolves the path inside
`gcc/`; use absolute patch paths.

### 6.4 Build the GNAT-LLVM compiler — `toolchain-setup-3.sh`

```bash
export PATH=/usr/lib/llvm-21/bin:/usr/local/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/usr/lib/llvm-21/lib
cd /opt/gnat-llvm/llvm-interface
make build PROCS=6 LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=clang-cpp \
           GNATMAKE=gnatmake-16
```

Produces `bin/llvm-gcc`, `bin/llvm-gnat1`, `bin/llvm-gnatbind`, ... (~30–40 min
on this machine). `llvm-gcc -v` should print `Target: llvm` /
`llvm-gcc version 16 (for GNAT 16.1.0)`.

### 6.5 Emscripten — `toolchain-setup-4a.sh`

```bash
git clone --depth 1 https://github.com/emscripten-core/emsdk.git /opt/emsdk
cd /opt/emsdk && ./emsdk install latest && ./emsdk activate latest
```

Installs SDK **6.0.10**.

### 6.6 Build the EH wasm runtime — `toolchain-setup-4b.sh`

```bash
export PATH=/opt/emsdk/upstream/emscripten:/opt/emsdk/node/24.19.0_64bit/bin:\
/usr/lib/llvm-21/bin:/usr/local/bin:/usr/bin:/bin
export EMCC=/opt/emsdk/upstream/emscripten/emcc
cd /opt/gnat-llvm/llvm-interface
make wasm-emcc-eh PROCS=6 LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=clang-cpp \
     GNATMAKE=gnatmake-16 EMCC="$EMCC"
```

Output: `lib/gnat-llvm/wasm32/rts-wasm-emcc-eh/` with `adalib/libgnat.a`.
This runtime contains the full EH machinery (`a-except`, `a-exexpr`,
`a-excmac`, `raise-gcc.c`, `wasm_eh_support.c`), `Ada.Text_IO`, `Ada.Calendar`,
containers and `Ada.Directories`.

### 6.7 Add `System.Expont` / `System.Exp_LLI` — `add-explli.sh`

HAC uses `System.Exp_LLI` (`Long_Long_Integer **`). In GCC 16 this now depends
on the generic `System.Expont`. Both are absent from the emcc RTS. The script
copies `s-expont.*`/`s-explli.*` from `gnat_src/libgnat`, compiles the bodies
(compiling the body also emits the spec ALI), and appends the objects to
`libgnat.a`.

### 6.8 Patch HAC — `patch-hac.sh`

GNAT 16's `Ada.Containers.Vectors` still carries the AI12-0400 compatibility
overload `Append (Container, New_Item : Vector)`, which makes two-element record
aggregates passed to `Append` ambiguous. The script qualifies them with the
element type:

```ada
-- before
Local_Defaults.Append ((CD.id_table (Name_Idx).adr_or_sz, Field_Default));
-- after
Local_Defaults.Append
  (Default_Component'(CD.id_table (Name_Idx).adr_or_sz, Field_Default));
```

It applies to `hac_sys-parser-type_def.adb` and `hac_sys-parser-defaults.adb`.

### 6.9 Build HAC to wasm — `build-hac.sh`

1. Copies HAC sources to `/opt/hac` (if absent) and applies `patch-hac.sh`.
2. Installs the `llvm` gprconfig target (`adawebpack_src/packages/Fedora/llvm.xml`)
   into `/usr/share/gprconfig/`, and creates the `llvm-gcc-16` wrapper (G2).
3. `gprbuild --target=llvm --RTS=<rts-wasm-emcc-eh> -c -b -P hac_wasm.gpr`
   (`poc/hac-wasm/hac_wasm.gpr`; source dirs point at `/opt/hac/src/...`).
4. Links with `emcc -fwasm-exceptions` twice:
   - `hac.js` + `hac.wasm` — ES module (`-sEXPORT_ES6`), for HTTP hosting.
   - `hac-standalone.js` — single file (`-sSINGLE_FILE=1`), classic script,
     wasm embedded as base64; works from `file://`.

Key link flags:

```
-fwasm-exceptions -O2 -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=16777216
-sMODULARIZE=1 -sEXPORT_NAME=createHacModule
-sINVOKE_RUN=0 -sEXIT_RUNTIME=0 -sERROR_ON_UNDEFINED_SYMBOLS=0
-sFORCE_FILESYSTEM=1 -sEXPORTED_RUNTIME_METHODS=FS,ccall
-sEXPORTED_FUNCTIONS=_main,_hac_run
--js-library ada_runtime_support.js
unwind_callpersonality.o .objs/*.o <rts>/adalib/libgnat.a
```

The Ada wrapper (`poc/hac-wasm/hac_runner.*`) exports:

```ada
procedure Run (File_Name : Interfaces.C.Strings.chars_ptr)
  with Export, Convention => C, Link_Name => "hac_run";
```

It calls `HAC_Sys.Builder.Build_Main_from_File` then
`HAC_Sys.PCode.Interpreter.Interpret_on_Current_IO`.

### 6.10 EH validation — `build-eh-smoke.sh`

Builds `poc/eh-smoke` (an Ada module that raises inside a nested subprogram and
catches in the caller) against the same runtime and runs it in Node. Expected:
`ada_try_raise(1) = 2`.

### 6.11 Bundle the npm package — `packages/ada-wasm`

```bash
cd packages/ada-wasm
npm run build     # dist/ada-wasm.iife.js + dist/index.d.ts
npm test          # Node end-to-end tests
```

`scripts/build.mjs` wraps `poc/hac-wasm/hac-standalone.js` (the single-file
runtime) together with `src/index.js` into one IIFE and exposes `AdaWasm` as a
global and as `module.exports`. The runtime's CommonJS branch is neutralised by
shadowing `module`/`exports`/`define` in the wrapper function, so the bundle
works as a classic script, a worker script, and a CommonJS module. The package
adds the `run(codeOrFiles, options)` API (stdin, multiple files, exit code) on
top of the raw `hac_run` export. The bundle is self-contained: the wasm is
embedded as base64, so no assets are hosted.

> Rebuild the runtime first (`build-hac.sh`) whenever the Ada wrapper or HAC
> changes, then rebuild the package bundle.

---

## 7. Gotchas and troubleshooting

**G1 — `gprconfig` cannot see Alire's GNAT.**
Ubuntu's `gprconfig-kb` extracts the target from a hardcoded path regexp
(`^   /usr/lib/gcc/.../adalib`). Alire installs under
`~/.local/share/alire/.../lib/gcc/...`, so detection fails and gprbuild reports
*"can't find a native toolchain for language 'ada'"*. Fix: use the distro
`gnat-16` (§6.2).

**G2 — version-suffixed driver name.**
The `llvm.xml` compiler description makes gprconfig derive the driver as
`llvm-gcc-<gcc_version>` → `llvm-gcc-16`. GNAT drivers dispatch on `argv[0]`, so
a symlink fails with *"unexpected program name"*. Create a **wrapper script**:

```sh
#!/bin/sh
exec "/opt/gnat-llvm/llvm-interface/bin/llvm-gcc" "$@"
```

**G3 — GCC 14 link driver rejects `--target=wasm32`.**
Only relevant to the old prebuilt AdaWebPack flow (`poc/adawebpack-smoke`),
where the workaround is to let gprbuild compile+bind and link with `wasm-ld`
manually. The EH toolchain links with `emcc` and does not hit this.

**G4 — Emscripten libunwind lacks `_Unwind_CallPersonality`.**
Emscripten 6.0.10's `Unwind-wasm.o` defines `__wasm_lpad_context` and the other
`_Unwind_*` entry points, but **not** `_Unwind_CallPersonality`, which LLVM's
`WasmEHPrepare` pass inserts into every landing pad. Without it, exceptions trap
with `Aborted(missing function: _Unwind_CallPersonality)`. Fix: link
`poc/eh-smoke/unwind_callpersonality.c` (a thin shim adapted from LLVM
libunwind). Re-check on Emscripten upgrades.

**G5 — missing `System.Exp_LLI` / `System.Expont`.**
See §6.7. Symptom: *"file s-explli.ads not found"* / *"construct not allowed in
configurable run-time mode"*.

**G6 — ambiguous `Append` aggregates.**
See §6.8. Symptom: *"ambiguous call to Append ... add type qualification to
aggregate actual"*.

**G7 — HAC requires the file base name to match the main subprogram.**
`Build_Main_from_File ("main.adb")` expects a unit named `MAIN`. The page
extracts the procedure name from the source and writes `/<Name>.adb`, then calls
`hac_run("<name>.adb")`.

**G8 — harmless `wasm-ld` warnings.**
Signature mismatches for `__gnat_lseek`, `strncpy`, `__gnat_dup2` between
`s-os_lib.o` and `adaint.o`/libc. Known RTS wart; safe unless those routines are
called.

**G9 — `Module.FS` / `ccall` are not exported by default.**
Add `-sFORCE_FILESYSTEM=1 -sEXPORTED_RUNTIME_METHODS=FS,ccall`.

**G10 — HAC output spacing.**
HAC's default `Integer_IO` width right-justifies integers (e.g.
`I squared =                   25`). This is HAC behaviour, not a bug.

**G11 — `gnat_exit_status` is a process global.**
`HAT.Set_Exit_Status` sets the runtime's `gnat_exit_status` variable
(`exit.c`), which persists for the life of the wasm instance. The wrapper
resets it to 0 at the start of every `hac_run` so repeated runs in one instance
do not inherit a previous program's status. The wrapper reads it back via an
`Import` of the `gnat_exit_status` object to report `exitCode`.

**G12 — Emscripten's stdin keeps its end-of-file flag across runs.**
When a run reads standard input up to EOF (e.g. `HAT.Get` on input with no
trailing newline), libc sets the EOF indicator on the `stdin` FILE. That flag
is not cleared between `hac_run` calls, so every subsequent run sees EOF
immediately and GNAT's `Ada.Text_IO` raises `End_Error`, which escaped as a
`WebAssembly.Exception` (`[object WebAssembly.Exception]` in the console). Fix:
`poc/hac-wasm/ada_reset.c` exports `ada_reset_stdin()` (a `clearerr(stdin)`),
linked into the runtime and called from the package before each `hac_run`. The
Ada wrapper also catches stray exceptions and reports them (e.g.
`ADA.IO_EXCEPTIONS.END_ERROR`) instead of letting them escape as wasm
exceptions.

---

## 8. Runtime capabilities (`rts-wasm-emcc-eh`)

| Area | Status |
|---|---|
| Ada exceptions (raise/catch across frames, finalization) | ✅ native wasm EH |
| `Ada.Text_IO` (console + file I/O over MEMFS) | ✅ |
| `Ada.Calendar`, `Ada.Directories`, `Ada.Streams.Stream_IO` | ✅ |
| `Ada.Containers` (incl. indefinite) | ✅ |
| `Ada.Environment_Variables`, `GNAT.OS_Lib` | ✅ |
| Tasking / protected objects | ❌ not supported on wasm32 |
| `Ada.Real_Time` | ❌ (use `Ada.Calendar`) |
| `Ada.Wide_*_IO` | ❌ |

HAC's own VM implements interpreted Ada exceptions itself, so the EH runtime is
needed for HAC's *compiler* code (and for `raise` in the interpreter's control
flow).

---

## 9. Pinned versions (summary)

| Tool | Version |
|---|---|
| HAC | 0.45, `8710a2c` |
| GNAT-LLVM fork | `28139a8` |
| GCC front-end sources | `6afcc4f` (`releases/gcc-16.1.0`) |
| AdaWebPack fork | `1ff162b` |
| bb-runtimes fork | `1b0f15a` (`gnat-fsf-15`) |
| llvm-bindings | `06933d3` |
| LLVM / Clang / lld | 21.1.8 |
| Emscripten | 6.0.10 |
| Host GCC/GNAT | 16.0.1 (2026-03-15, `ppa:ubuntu-toolchain-r/test`) |
| gprbuild | 2024.1.20231009 (Ubuntu 24.04) |
| Node (Emscripten SDK) | 24.19.0 |
| Windows Node (tests) | 24.x |

---

## 10. How to update

**HAC (most common).**
1. `git -C /opt/hac fetch && git -C /opt/hac checkout <new-commit>`
   (or delete `/opt/hac` and let `build-hac.sh` re-copy).
2. Re-run `patch-hac.sh` — if HAC changed the affected lines, the script prints
   `WARNING: target line not found` and the patch must be refreshed.
3. Re-run `build-hac.sh`. Watch for new compile errors (new RTS units may be
   required, à la `s-explli`) and for new ambiguous aggregates.
4. Re-run `test.mjs` / `test-standalone.cjs`; open `index.html`.

**GNAT-LLVM / AdaWebPack / bb-runtimes.**
1. Update the fork checkouts; re-apply the three GCC patches (they may need
   refreshing against a new GCC tag).
2. `make build` (§6.4), then `make wasm-emcc-eh` (§6.6).
3. **Re-apply `add-explli.sh`** — the runtime is rebuilt from scratch, so the
   extra `s-expont`/`s-explli` objects must be added again.
4. Rebuild HAC (§6.9) and re-validate EH (§6.10).

**LLVM / Emscripten.**
- LLVM must stay at **21.x** for this GNAT-LLVM fork.
- On an Emscripten bump, re-check `_Unwind_CallPersonality` (G4) and the
  `FS`/`ccall` exports (G9).

**Record the new pins** in §4/§9 and in `poc/scripts/pins.sh`.

---

## 11. Verification

```bash
# run from the repository root, with Node on the host (Windows here)
node poc/eh-smoke/test.mjs            # EH runtime: raise/catch across frames
node poc/hac-wasm/test.mjs            # HAC, ES-module build
node poc/hac-wasm/test-rerun.mjs      # HAC, two programs in one instance
node poc/hac-wasm/test-standalone.cjs # HAC, single-file classic build (browser path)
```

Expected outputs are recorded in §1 and §6.10.

---

## 12. Repository layout

```
browser-ada/
  FINDINGS.md                     # this file
  README.md                       # usage of the built module / page
  packages/
    ada-wasm/                     # npm package @live-codes/ada-wasm (single IIFE)
      src/index.js                # runtime wrapper (createRuntime/run)
      src/index.d.ts              # types
      scripts/build.mjs           # concatenates runtime + wrapper -> dist
      dist/ada-wasm.iife.js       # built bundle (wasm embedded as base64)
      test/                       # Node end-to-end tests
      LICENSE                     # MIT, Copyright (c) 2026 Hatem Hosny
      NOTICE                      # bundled third-party licenses
      README.md
  poc/
    hac-wasm/                     # THE POC
      index.html                  # self-contained page (uses hac-standalone.js)
      hac.js, hac.wasm            # ES-module build (HTTP hosting)
      hac-standalone.js           # single-file build (file:// / classic script)
      hac_runner.ads/.adb         # Ada wrapper exporting hac_run
      hac_wasm.gpr                # project file
      main.adb                    # binder main
      test.mjs, test-rerun.mjs, test-standalone.cjs
    eh-smoke/                     # exception-propagation validation
      demo.*, main.adb, test.gpr, test.mjs
      unwind_callpersonality.c    # Emscripten libunwind shim
      ada_runtime_support.js
    adawebpack-smoke/             # original (non-EH) prebuilt-toolchain smoke test
    scripts/                      # all build scripts (see §6)
```
