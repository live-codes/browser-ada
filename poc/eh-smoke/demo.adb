package body Demo is

   use type Interfaces.Integer_32;

   function Add (A, B : Interfaces.Integer_32) return Interfaces.Integer_32 is
   begin
      return A + B;
   end Add;

   function Fib (N : Interfaces.Integer_32) return Interfaces.Integer_32 is
   begin
      if N < 2 then
         return N;
      else
         return Fib (N - 1) + Fib (N - 2);
      end if;
   end Fib;

   --  Raise in a nested subprogram, handle in the caller: proves that
   --  exceptions propagate across frames on the wasm EH runtime.
   function Try_Raise (X : Interfaces.Integer_32) return Interfaces.Integer_32 is
      E : exception;

      function Nested (Value : Interfaces.Integer_32) return Interfaces.Integer_32 is
      begin
         if Value > 0 then
            raise E;
         end if;
         return 1;
      end Nested;
   begin
      return Nested (X) + 1;
   exception
      when E =>
         return 2;
   end Try_Raise;

end Demo;
