/** A source file to compile. HAC requires the file base name to match the
 *  main subprogram name (e.g. `Hello` in `hello.adb`). */
export interface AdaFile {
  filename: string;
  content: string;
}

export interface RunOptions {
  /** Standard input handed to the program (string or raw bytes). */
  input?: string | Uint8Array | ArrayBuffer;
  /** Alias for `input`. */
  stdin?: string | Uint8Array | ArrayBuffer;
  /** Extra files to add to the module (merged with the array argument). */
  files?: AdaFile[];
  /** Force which file is the main unit. Defaults to `main.adb`, then the file
   *  whose base name matches its main subprogram, then the first file. */
  mainFile?: string;
}

export interface RunResult {
  /** Everything the program wrote to standard output. */
  stdout: string;
  /** Compiler diagnostics and anything written to standard error. */
  stderr: string;
  /** stdout and stderr in write order. */
  output: string;
  /** Program exit status: 0 on success, 1 on compile failure or unhandled VM
   *  exception, otherwise the value set with `HAT.Set_Exit_Status`. */
  exitCode: number;
  /** `stderr` split into lines. */
  diagnostics: string[];
  /** Wall-clock milliseconds for compile + run. */
  runMs: number;
}

export interface RuntimeOptions {
  /** Called with `{ phase, loaded, total }` as the runtime initialises. */
  onProgress?: (progress: { phase: string; loaded: number; total: number }) => void;
}

export interface AdaRuntime {
  /** Instantiate the WebAssembly runtime (idempotent). `run` calls it too. */
  warmUp(): Promise<void>;
  /** Compile and run Ada source. */
  run(codeOrFiles: string | AdaFile[] | Record<string, string>, optionsOrInput?: RunOptions | string): Promise<RunResult>;
}

export interface AdaWasmGlobal {
  readonly version: string;
  createRuntime(options?: RuntimeOptions): Promise<AdaRuntime>;
  /** One-shot convenience using a shared runtime. */
  run(codeOrFiles: string | AdaFile[] | Record<string, string>, optionsOrInput?: RunOptions | string): Promise<RunResult>;
}

declare const AdaWasm: AdaWasmGlobal;
export default AdaWasm;
