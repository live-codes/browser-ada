--  Browser entry point for HAC.
--
--  The Ada source to compile is expected to already exist as a file (in the
--  Emscripten MEMFS, written by JavaScript before the call), named after its
--  main subprogram.  Output produced by the interpreted program goes to
--  standard output, which Emscripten captures (Module.print).

with HAC_Sys.Builder,
     HAC_Sys.PCode.Interpreter;

with Ada.Text_IO;
with Interfaces.C.Strings;

package body HAC_Runner is

   procedure Run (File_Name : Interfaces.C.Strings.chars_ptr) is
      use HAC_Sys.PCode.Interpreter;
      BD          : HAC_Sys.Builder.Build_Data;
      post_mortem : Post_Mortem_Data;
   begin
      BD.Build_Main_from_File (Interfaces.C.Strings.Value (File_Name));

      if BD.Build_Successful then
         Interpret_on_Current_IO (BD, 1, "", post_mortem);

         if Is_Exception_Raised (post_mortem.Unhandled) then
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               "HAC VM: raised " & Image (post_mortem.Unhandled));
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error, Message (post_mortem.Unhandled));
         end if;
      end if;
   end Run;

end HAC_Runner;
