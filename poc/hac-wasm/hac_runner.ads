with Interfaces.C.Strings;

package HAC_Runner is

   --  Compile and run the Ada program stored in the MEMFS file whose name is
   --  given (a NUL-terminated C string, e.g. "hello.adb").
   procedure Run (File_Name : Interfaces.C.Strings.chars_ptr)
     with Export     => True,
          Convention => C,
          Link_Name  => "hac_run";

end HAC_Runner;
