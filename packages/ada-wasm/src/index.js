/* SPDX-License-Identifier: MIT
   Copyright (c) 2026 Hatem Hosny */

/* AdaWasm — a small browser runtime around the HAC Ada compiler compiled to
   WebAssembly.

   This file is a plain script, not a module: the build concatenates it with
   the single-file HAC runtime (which defines `createHacModule`) inside one
   IIFE and exposes the result as `AdaWasm` (global) / `module.exports`. */

var AdaWasm = (function () {
  var VERSION = "0.1.0";
  var EXT = /\.(adb|ads)$/i;

  function now() {
    return typeof performance !== "undefined" && performance.now
      ? performance.now()
      : Date.now();
  }

  // HAC requires the main unit's file base name to match the subprogram name.
  function mainName(source) {
    var m = String(source).match(/\b(?:procedure|function)\s+([A-Za-z][A-Za-z0-9_]*)/i);
    return m ? m[1] : "main";
  }

  function withExt(name) {
    return EXT.test(name) ? name : name + ".adb";
  }

  function baseName(name) {
    return String(name).replace(EXT, "");
  }

  function normalizeOptions(o) {
    if (o == null) return {};
    if (typeof o === "string") return { input: o };
    if (typeof o === "object") return o;
    return {};
  }

  function asFile(f, fallbackName) {
    return {
      filename: withExt((f && f.filename) || fallbackName),
      content: String(f && f.content != null ? f.content : ""),
    };
  }

  function normalizeFiles(codeOrFiles, opts) {
    var files = [];
    var i;

    if (typeof codeOrFiles === "string") {
      files.push({ filename: withExt(mainName(codeOrFiles)), content: codeOrFiles });
    } else if (codeOrFiles && typeof codeOrFiles.length === "number") {
      for (i = 0; i < codeOrFiles.length; i++) {
        files.push(asFile(codeOrFiles[i], "file" + i));
      }
    } else if (codeOrFiles && typeof codeOrFiles === "object") {
      // Convenience: a plain { "name.adb": "source" } map.
      for (var key in codeOrFiles) {
        if (Object.prototype.hasOwnProperty.call(codeOrFiles, key)) {
          files.push({ filename: withExt(key), content: String(codeOrFiles[key]) });
        }
      }
    }

    if (opts.files && opts.files.length) {
      for (i = 0; i < opts.files.length; i++) {
        files.push(asFile(opts.files[i], "extra" + i));
      }
    }

    if (!files.length) throw new Error("ada-wasm: no source provided");
    return files;
  }

  // Decide which file carries the main subprogram.
  function pickMain(files, opts) {
    var i, f, b, re;

    if (opts.mainFile) {
      var wanted = baseName(opts.mainFile).toLowerCase();
      for (i = 0; i < files.length; i++) {
        if (baseName(files[i].filename).toLowerCase() === wanted) return files[i].filename;
      }
    }

    for (i = 0; i < files.length; i++) {
      if (baseName(files[i].filename).toLowerCase() === "main") return files[i].filename;
    }

    for (i = 0; i < files.length; i++) {
      f = files[i];
      b = baseName(f.filename);
      re = new RegExp("\\b(?:procedure|function)\\s+" + b + "\\b", "i");
      if (re.test(f.content)) return f.filename;
    }

    return files[0].filename;
  }

  function makeStdin(input) {
    if (input == null) return function () { return null; };

    var bytes;
    if (typeof Uint8Array !== "undefined" && input instanceof Uint8Array) {
      bytes = input;
    } else if (typeof ArrayBuffer !== "undefined" && input instanceof ArrayBuffer) {
      bytes = new Uint8Array(input);
    } else {
      bytes = new TextEncoder().encode(String(input));
    }

    var i = 0;
    return function () { return i < bytes.length ? bytes[i++] : null; };
  }

  function cleanMemfs(Module) {
    var names;
    try { names = Module.FS.readdir("/"); } catch (e) { return; }
    for (var i = 0; i < names.length; i++) {
      var n = names[i];
      if (n === "." || n === "..") continue;
      if (EXT.test(n)) {
        try { Module.FS.unlink("/" + n); } catch (e2) { /* ignore */ }
      }
    }
  }

  function joinLines(lines) {
    return lines.length ? lines.join("\n") + "\n" : "";
  }

  /**
   * Create an Ada runtime. Instantiation of the embedded wasm is deferred
   * until warmUp()/run().
   */
  function createRuntime(options) {
    options = options || {};
    var modulePromise = null;
    var current = null;
    var stdinProvider = null;

    function instantiate() {
      if (!modulePromise) {
        if (typeof options.onProgress === "function") {
          options.onProgress({ phase: "init", loaded: 0, total: 0 });
        }
        modulePromise = createHacModule({
          print: function (s) {
            if (current) { current.stdout.push(s); current.all.push({ fd: 1, s: s }); }
          },
          printErr: function (s) {
            if (current) { current.stderr.push(s); current.all.push({ fd: 2, s: s }); }
          },
          stdin: function () { return stdinProvider ? stdinProvider() : null; },
        }).then(function (Module) {
          Module._main(); // elaborate HAC itself
          if (typeof options.onProgress === "function") {
            options.onProgress({ phase: "ready", loaded: 1, total: 1 });
          }
          return Module;
        });
      }
      return modulePromise;
    }

    function warmUp() {
      return instantiate();
    }

    /**
     * Compile and run Ada.
     *
     * @param {string|Array<{filename:string,content:string}>|Object} codeOrFiles
     * @param {string|{input?:string|Uint8Array,files?:Array,mainFile?:string}} [optionsOrInput]
     * @returns {Promise<{stdout:string,stderr:string,output:string,exitCode:number,diagnostics:string[],runMs:number}>}
     */
    async function run(codeOrFiles, optionsOrInput) {
      var opts = normalizeOptions(optionsOrInput);
      var files = normalizeFiles(codeOrFiles, opts);
      var main = pickMain(files, opts);
      var Module = await instantiate();

      cleanMemfs(Module);
      for (var i = 0; i < files.length; i++) {
        Module.FS.writeFile("/" + files[i].filename, files[i].content);
      }

      stdinProvider = makeStdin(opts.input != null ? opts.input : opts.stdin);
      var cap = { stdout: [], stderr: [], all: [] };
      current = cap;

      var t0 = now();
      var exitCode;
      try {
        // Emscripten's libc keeps the stdin end-of-file flag across runs, which
        // would make a repeated run read EOF immediately. Clear it first.
        if (typeof Module._ada_reset_stdin === 'function') {
          Module._ada_reset_stdin();
        }
        exitCode = Module.ccall("hac_run", "number", ["string"], [main]);
      } finally {
        current = null;
        stdinProvider = null;
      }
      var t1 = now();

      return {
        stdout: joinLines(cap.stdout),
        stderr: joinLines(cap.stderr),
        output: joinLines(cap.all.map(function (x) { return x.s; })),
        exitCode: exitCode,
        diagnostics: cap.stderr.slice(),
        runMs: Math.round((t1 - t0) * 1000) / 1000,
      };
    }

    return Promise.resolve({
      warmUp: warmUp,
      run: run,
    });
  }

  var sharedRuntime = null;

  /** One-shot convenience: creates a shared runtime on first use. */
  function run(codeOrFiles, optionsOrInput) {
    if (!sharedRuntime) sharedRuntime = createRuntime({});
    return sharedRuntime.then(function (runtime) {
      return runtime.run(codeOrFiles, optionsOrInput);
    });
  }

  return {
    version: VERSION,
    createRuntime: function (options) { return createRuntime(options); },
    run: run,
  };
})();
