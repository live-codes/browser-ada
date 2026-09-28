// Emscripten JS library providing the GNAT runtime hooks that the AdaWebPack
// wasm RTS expects as imports.
mergeInto(LibraryManager.library, {
  __gnat_put_exception: function (address, size, line) {
    var msg = UTF8ToString(address, size);
    console.error('Ada exception: ' + msg + ' (line ' + line + ')');
  },

  __gnat_grow: function (size) {
    // Memory growth is handled by Emscripten (ALLOW_MEMORY_GROWTH); return
    // success to satisfy any caller.
    return 0;
  }
});
