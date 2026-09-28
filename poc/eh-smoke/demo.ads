with Interfaces;

package Demo is

   function Add (A, B : Interfaces.Integer_32) return Interfaces.Integer_32
     with Export     => True,
          Convention => C,
          Link_Name  => "ada_add";

   function Fib (N : Interfaces.Integer_32) return Interfaces.Integer_32
     with Export     => True,
          Convention => C,
          Link_Name  => "ada_fib";

   function Try_Raise (X : Interfaces.Integer_32) return Interfaces.Integer_32
     with Export     => True,
          Convention => C,
          Link_Name  => "ada_try_raise";

end Demo;
