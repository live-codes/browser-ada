--  Browser entry point for HAC.
--
--  The Ada source to compile is expected to already exist as a file (in the
--  Emscripten MEMFS, written by JavaScript before the call), named after its
--  main subprogram.  Output produced by the interpreted program goes to
--  standard output, which Emscripten captures (Module.print); compiler
--  diagnostics go to standard error (Module.printErr).

with HAC_Sys.Builder,
     HAC_Sys.PCode.Interpreter;

with Ada.Text_IO;
with Interfaces;
with Interfaces.C;
with Interfaces.C.Strings;

package body HAC_Runner is

   --  Set by Ada.Command_Line.Set_Exit_Status (i.e. HAT.Set_Exit_Status).
   Gnat_Exit_Status : Interfaces.C.int
     with Import, Convention => C, Link_Name => "gnat_exit_status";

   function Run (File_Name : Interfaces.C.Strings.chars_ptr)
     return Interfaces.Integer_32
   is
      use HAC_Sys.PCode.Interpreter;
      BD          : HAC_Sys.Builder.Build_Data;
      post_mortem : Post_Mortem_Data;
   begin
      --  The exit status is a process-global; reset it so repeated runs in one
      --  instance do not inherit a previous program's status.
      Gnat_Exit_Status := 0;

      BD.Build_Main_from_File (Interfaces.C.Strings.Value (File_Name));

      if not BD.Build_Successful then
         return 1;
      end if;

      Interpret_on_Current_IO (BD, 1, "", post_mortem);

      if Is_Exception_Raised (post_mortem.Unhandled) then
         Ada.Text_IO.Put_Line
           (Ada.Text_IO.Standard_Error,
            "HAC VM: raised " & Image (post_mortem.Unhandled));
         Ada.Text_IO.Put_Line
           (Ada.Text_IO.Standard_Error, Message (post_mortem.Unhandled));
         return 1;
      end if;

      return Interfaces.Integer_32 (Gnat_Exit_Status);
   end Run;

end HAC_Runner;
