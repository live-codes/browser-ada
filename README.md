# browser-ada

Run **Ada in the browser** — fully client-side, no server.

This repository is a proof of concept for adding Ada support to
[LiveCodes](https://livecodes.io). It compiles **HAC** (a small Ada-subset
compiler and p-code interpreter written in Ada) to WebAssembly using an
EH-enabled **GNAT-LLVM** toolchain, so that arbitrary Ada source can be
compiled and executed inside the page.

For the full technical background, toolchain build, dependency licenses and
upgrade instructions, see **[FINDINGS.md](FINDINGS.md)**.

---

## What's here

| Path | Description |
|---|---|
| `poc/hac-wasm/index.html` | Self-contained demo page (opens from disk, no server) |
| `poc/hac-wasm/hac-standalone.js` | Single-file build: classic script with the wasm embedded as base64 |
| `poc/hac-wasm/hac.js` + `hac.wasm` | ES-module build (serve over HTTP) |
| `poc/hac-wasm/hac_runner.ads/.adb` | Ada wrapper exporting `hac_run` |
| `poc/eh-smoke/` | Exception-propagation validation harness |
| `poc/scripts/` | Toolchain + build scripts |
| `FINDINGS.md` | Technical reference and build process |

---

## Quick start

**Just open the page.** Double-click `poc/hac-wasm/index.html` (or open it with
`file://`). The wasm binary is embedded in `hac-standalone.js`, so no web server
is required. Edit the Ada program and press **Run** (or `Ctrl+Enter`).

```ada
with HAT;

procedure Demo is
begin
  HAT.Put_Line ("Hello from Ada, compiled and run in your browser!");
end Demo;
```

> If you prefer to serve it (or use the ES-module build), run any static server
> from `poc/hac-wasm/`, e.g. `python -m http.server`, and open `index.html`.

---

## Using the module programmatically

### ES module (`hac.js` + `hac.wasm`)

```js
import createHacModule from './hac.js';

const stdout = [];
const stderr = [];

const Module = await createHacModule({
  print:    (line) => stdout.push(line),   // program output (Ada.Text_IO stdout)
  printErr: (line) => stderr.push(line),   // compiler diagnostics / errors
});

// Elaborate HAC itself. Call this exactly once, before hac_run.
Module._main();

const source = `
with HAT;
procedure Hello is
begin
  HAT.Put_Line ("hi");
end Hello;
`;

// HAC requires the file base name to match the main subprogram name.
Module.FS.writeFile('/Hello.adb', source);

// Compile and run.
Module.ccall('hac_run', null, ['string'], ['Hello.adb']);

console.log(stdout.join('\n'));
```

### Single-file / classic script (`hac-standalone.js`)

```html
<script src="hac-standalone.js"></script>
<script>
  createHacModule({ print: console.log, printErr: console.error })
    .then((Module) => {
      Module._main();
      Module.FS.writeFile('/Hello.adb', 'with HAT; procedure Hello is begin HAT.Put_Line ("hi"); end Hello;');
      Module.ccall('hac_run', null, ['string'], ['Hello.adb']);
    });
</script>
```

### API contract

| Item | Meaning |
|---|---|
| `createHacModule(opts)` | Async factory. `opts.print` / `opts.printErr` receive output lines. Returns the Emscripten `Module`. |
| `Module._main()` | Elaborates HAC. **Required once** before any `hac_run`. |
| `Module.FS.writeFile(path, text)` | Writes a source file into the in-memory (MEMFS) filesystem. `path` is absolute, e.g. `/Hello.adb`. |
| `Module.ccall('hac_run', null, ['string'], [name])` | Compiles and runs the MEMFS file `name` (e.g. `"Hello.adb"`). |
| `opts.print` | Normal program output (HAC routes `Ada.Text_IO` to stdout). |
| `opts.printErr` | Compiler errors/warnings and unhandled VM exceptions. |

The same `Module` can be reused for multiple runs: write the next file and call
`hac_run` again.

---

## Writing Ada for HAC

HAC implements a subset of Ada 2022, roughly the "Pascal subset plus packages":
no access types (pointers), no generics, only constrained types. See the
[HAC documentation](https://github.com/zertovitch/hac) for the full list.

Conventions for this POC:

- **I/O uses the built-in `HAT` package** — no source file needed:

  ```ada
  with HAT; use HAT;
  Put_Line ("text");
  Put (42);
  ```

- **The main subprogram name must match the source file name.** The page
  extracts the first `procedure <Name>` from the source and writes
  `/<Name>.adb` automatically. If you drive the module yourself, do the same.

- **Multi-file programs**: HAC resolves `with`-ed user units through the
  filesystem, so write each unit to `/<unit-name>.adb` in MEMFS before calling
  `hac_run`. Only the main file name is passed to `hac_run`.

- **Interactive input** (`Get`/`Get_Line`) is not wired up in this POC; programs
  should not read from standard input.

---

## Building from source

The toolchain is large (GCC 16 + LLVM 21 + Emscripten) and is built inside WSL.
The complete, scripted process — prerequisites, exact commands, pinned commits,
licenses and troubleshooting — is in **[FINDINGS.md](FINDINGS.md)** §6.

In short:

```bash
# once: build the EH-enabled GNAT-LLVM toolchain + wasm runtime
wsl -d <distro> -- bash poc/scripts/toolchain-setup-1.sh
wsl -d <distro> -- bash poc/scripts/toolchain-setup-1b.sh
wsl -d <distro> -- bash poc/scripts/toolchain-setup-2.sh
wsl -d <distro> -- bash poc/scripts/toolchain-setup-2b.sh
wsl -d <distro> -- bash poc/scripts/toolchain-setup-3.sh
wsl -d <distro> -- bash poc/scripts/toolchain-setup-4a.sh
wsl -d <distro> -- bash poc/scripts/toolchain-setup-4b.sh
wsl -d <distro> -- bash poc/scripts/add-explli.sh

# whenever HAC or its sources change: rebuild the wasm
wsl -d <distro> -- bash poc/scripts/build-hac.sh
```

`build-hac.sh` regenerates `poc/hac-wasm/{hac.js,hac.wasm,hac-standalone.js}`.

---

## Testing

```bash
node poc/hac-wasm/test.mjs            # ES-module build
node poc/hac-wasm/test-rerun.mjs      # two programs in one instance
node poc/hac-wasm/test-standalone.cjs # single-file build (browser path)
node poc/eh-smoke/test.mjs            # exception propagation
```

---

## Licenses

This repository's own code is provided as a proof of concept. The built
artifacts bundle third-party components:

- **HAC** — MIT.
- **GNAT-LLVM**, **GCC 16**, **bb-runtimes**, **AdaWebPack runtime** —
  GPL-3.0-or-later **with the GCC Runtime Library Exception** (the exception
  permits distributing compiled programs without imposing the GPL).
- **AdaWebPack Web API bindings** — BSD-3-Clause.
- **LLVM/Clang**, `unwind_callpersonality.c` — Apache-2.0 WITH LLVM-exception.
- **Emscripten** — MIT / University of Illinois NCSA.

See [FINDINGS.md](FINDINGS.md) §4 for the full table with links and versions.
