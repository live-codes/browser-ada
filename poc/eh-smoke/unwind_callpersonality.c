/* Emscripten's bundled libunwind (Unwind-wasm.o) defines the wasm _Unwind_*
   layer and the __wasm_lpad_context global, but (as of Emscripten 6.0.10) no
   longer exports _Unwind_CallPersonality.  The LLVM WasmEHPrepare pass inserts
   a call to it in every landing pad, and GNAT's wasm raise-gcc.c expects it,
   so provide the thin shim here (same ABI as LLVM's Unwind-wasm.c).

   __wasm_lpad_context layout {lpad_index, lsda, selector} and the symbol name
   are an ABI contract with LLVM. */

#include <stdint.h>
#include <unwind.h>

struct _Unwind_LandingPadContext {
  uintptr_t lpad_index;
  uintptr_t lsda;
  uintptr_t selector;
};

extern struct _Unwind_LandingPadContext __wasm_lpad_context;

/* Defined in raise-gcc.c: routes to the GNAT personality on wasm. */
extern _Unwind_Reason_Code
__gxx_personality_wasm0 (int version,
                         _Unwind_Action actions,
                         _Unwind_Exception_Class exception_class,
                         _Unwind_Exception *unwind_exception,
                         struct _Unwind_Context *context);

_Unwind_Reason_Code
_Unwind_CallPersonality (void *exception_ptr)
{
  _Unwind_Exception *exception_object = (_Unwind_Exception *) exception_ptr;

  __wasm_lpad_context.selector = 0;

  return __gxx_personality_wasm0
    (1, _UA_SEARCH_PHASE, exception_object->exception_class, exception_object,
     (struct _Unwind_Context *) &__wasm_lpad_context);
}
