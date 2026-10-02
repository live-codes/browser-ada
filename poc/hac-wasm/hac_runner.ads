with Interfaces;
with Interfaces.C.Strings;

package HAC_Runner is

   --  Compile and run the Ada program stored in the MEMFS file whose name is
   --  given (a NUL-terminated C string, e.g. "hello.adb").
   --
   --  Returns the process exit status: 0 on success, 1 if compilation failed
   --  or an unhandled VM exception was raised, otherwise the status set by the
   --  program via HAT.Set_Exit_Status.
   function Run (File_Name : Interfaces.C.Strings.chars_ptr)
     return Interfaces.Integer_32
     with Export     => True,
          Convention => C,
          Link_Name  => "hac_run";

end HAC_Runner;
