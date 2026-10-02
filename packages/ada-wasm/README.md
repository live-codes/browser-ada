# @live-codes/ada-wasm

Run **Ada** in the browser — compile and execute, fully client-side, with no
server. A single IIFE bundle around [HAC](https://github.com/zertovitch/hac)
(the Ada-subset compiler and p-code VM, written in Ada) compiled to
WebAssembly.

Shaped as the adapter package for Ada support in
[LiveCodes](https://livecodes.io), alongside
[`@live-codes/clang-wasm`](https://www.npmjs.com/package/@live-codes/clang-wasm)
and
[`@live-codes/swift-wasm`](https://www.npmjs.com/package/@live-codes/swift-wasm).

The bundle is self-contained: the WebAssembly binary is embedded as base64, so
there are no separate assets to host and nothing to fetch.

```js
AdaWasm.run(`
  with HAT; use HAT;
  procedure Hello is
  begin
    Put_Line ("Hello from Ada!");
  end Hello;
`).then(({ stdout, stderr, exitCode }) => {
  console.log(stdout);   // "Hello from Ada!\n"
  console.log(exitCode); // 0
});
```

---

## Install

```sh
npm install @live-codes/ada-wasm
```

Or load it directly (it sets `globalThis.AdaWasm`):

```html
<script src="https://unpkg.com/@live-codes/ada-wasm/dist/ada-wasm.iife.js"></script>
<script>
  AdaWasm.run('with HAT; use HAT; procedure H is begin Put_Line ("hi"); end H;')
    .then((r) => console.log(r.stdout));
</script>
```

In a web worker: `importScripts('.../ada-wasm.iife.js')`, then use
`self.AdaWasm`.

In Node/CommonJS: `const AdaWasm = require('@live-codes/ada-wasm')`.

---

## API

### `AdaWasm.run(codeOrFiles, optionsOrInput?) => Promise<RunResult>`

One-shot convenience using a shared runtime. `optionsOrInput` is either the
stdin string or a `RunOptions` object.

### `AdaWasm.createRuntime(options?) => Promise<AdaRuntime>`

Creates a runtime with its own instance of the compiler. Useful to warm it up
ahead of time or to keep it isolated.

```js
const runtime = await AdaWasm.createRuntime({
  onProgress: (p) => console.log(p.phase, p.loaded, p.total),
});
await runtime.warmUp();
const result = await runtime.run(source, { input: '42\n' });
```

| Method | Description |
| --- | --- |
| `runtime.warmUp()` | Instantiate the WebAssembly runtime (idempotent; `run` calls it too). |
| `runtime.run(codeOrFiles, optionsOrInput?)` | Compile and run; see below. |

### Input

`codeOrFiles` is one of:

- a **source string** — the file is named after the main subprogram (HAC
  requires the file base name to match the subprogram name), e.g. `Hello` →
  `Hello.adb`;
- an **array of files** — `[{ filename, content }, ...]` for multi-unit
  programs;
- a **plain object map** — `{ 'main.adb': '...', 'helper.adb': '...' }`.

For a module, the main file is chosen as: `options.mainFile`, else `main.adb`,
else the file whose base name matches its main subprogram, else the first file.

### `RunOptions`

| Option | Meaning |
| --- | --- |
| `input` | Standard input, as a `string` or `Uint8Array`/`ArrayBuffer`. |
| `stdin` | Alias for `input`. |
| `files` | Extra files to add when `codeOrFiles` is a string. |
| `mainFile` | Force which file is the main unit. |

As a shorthand, the second argument may be the stdin string directly:

```js
await AdaWasm.run(source, 'line 1\nline 2\n');
```

### `RunResult`

| Field | Meaning |
| --- | --- |
| `stdout` | Everything the program wrote to standard output. |
| `stderr` | Compiler diagnostics and anything written to standard error. |
| `output` | `stdout` and `stderr` in the order they were written. |
| `exitCode` | `0` on success, `1` on compile failure or unhandled VM exception, otherwise the value set by `HAT.Set_Exit_Status`. |
| `diagnostics` | `stderr` split into lines. |
| `runMs` | Wall-clock milliseconds for compile + run. |

---

## Examples

### stdin

```js
const { stdout } = await AdaWasm.run(`
  with HAT; use HAT;
  procedure Echo is
    V : VString;
  begin
    Get_Line (V);
    Put_Line ("you said: " & V);
  end Echo;
`, 'hello\n');
// stdout === "you said: hello\n"
```

### Multiple files

```js
const { stdout } = await AdaWasm.run([
  { filename: 'main.adb',   content: 'with Helper;\nprocedure Main is begin Helper.Greeting; end Main;' },
  { filename: 'helper.ads', content: 'package Helper is procedure Greeting; end Helper;' },
  { filename: 'helper.adb', content: 'with HAT; use HAT;\npackage body Helper is\n  procedure Greeting is begin Put_Line ("from helper"); end Greeting;\nend Helper;' },
]);
// stdout === "from helper\n"
```

### Exit status and errors

```js
const { exitCode, stderr } = await AdaWasm.run(`
  with HAT; use HAT;
  procedure Fail is
  begin
    Set_Exit_Status (3);
  end Fail;
`);
// exitCode === 3

const bad = await AdaWasm.run('procedure Nope is begin end Nope;'); // missing "with HAT"
// bad.exitCode === 1
// bad.stderr contains the compiler diagnostic
```

---

## Writing Ada for HAC

HAC implements a subset of Ada 2022 (roughly the Pascal subset plus packages):
no access types, no generics, only constrained types. See the
[HAC repository](https://github.com/zertovitch/hac) for details.

- Use the built-in `HAT` package for I/O (`with HAT; use HAT;`).
- The main subprogram name must match its file name.
- `HAT.Set_Exit_Status (Code)` sets `exitCode`.
- `Ada.Text_IO` file I/O works over the in-memory filesystem; write extra units
  with the files API.

Not available: tasking/protected objects and `Ada.Real_Time` (wasm32 limits).

---

## Building the bundle

The bundle is committed, so consumers need nothing. To rebuild after changing
`src/` or the HAC runtime:

```sh
npm run build   # regenerates dist/ada-wasm.iife.js and dist/index.d.ts
npm test        # Node end-to-end tests
```

`scripts/build.mjs` concatenates `poc/hac-wasm/hac-standalone.js` (the
single-file HAC runtime) with `src/index.js` into one IIFE. See
[`FINDINGS.md`](../../FINDINGS.md) for how that runtime is produced.

---

## License

**MIT © 2026 Hatem Hosny** — see [`LICENSE`](LICENSE).

The bundle embeds third-party components whose licenses are compatible with
MIT. The GNAT/AdaWebPack WebAssembly runtime is GPL-3.0-or-later **with the GCC
Runtime Library Exception**, which permits conveying a program that links the
runtime under terms of your choice, provided the runtime's corresponding source
is made available. Full attributions and source links are in
[`NOTICE`](NOTICE); the dependency table is in
[`FINDINGS.md`](../../FINDINGS.md) §4.

- **HAC** — MIT.
- **GNAT runtime / GNAT-LLVM / GCC 16 / bb-runtimes / AdaWebPack runtime** —
  GPL-3.0-or-later with the GCC Runtime Library Exception.
- **AdaWebPack Web API bindings** — BSD-3-Clause.
- **LLVM/Clang**, the `_Unwind_CallPersonality` shim — Apache-2.0 WITH
  LLVM-exception.
- **Emscripten** — MIT / University of Illinois NCSA.
