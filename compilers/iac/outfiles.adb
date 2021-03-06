------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                             O U T F I L E S                              --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2007-2012, Free Software Foundation, Inc.          --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.                                               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
--                  PolyORB is maintained by AdaCore                        --
--                     (email: sales@adacore.com)                           --
--                                                                          --
------------------------------------------------------------------------------

with Flags;  use Flags;
with Namet;  use Namet;
with Output; use Output;

with Ada.Containers.Ordered_Sets;

package body Outfiles is

   package Name_Sets is new Ada.Containers.Ordered_Sets
     (Element_Type => Name_Id);
   use Name_Sets;

   File_Names_Seen : Name_Sets.Set := Empty_Set;

   ----------------
   -- Set_Output --
   ----------------

   function Set_Output (File_Name : Name_Id) return File_Descriptor is
      Fd : File_Descriptor;
   begin
      if not Use_Stdout then
         --  Assert that we don't try to write the same file twice. Insert will
         --  raise Constraint_Error if the same name is inserted again.

         pragma Debug (Insert (File_Names_Seen, File_Name));

         if Output_Directory /= null then
            Set_Str_To_Name_Buffer (Output_Directory.all);
         else
            Name_Len := 0;
         end if;
         Get_Name_String_And_Append (File_Name);

         --  Create file, overwriting any pre-existing file by the same name

         Fd := Create_File (Name_Buffer (1 .. Name_Len), Binary);

         if Fd = Invalid_FD then
            raise Program_Error;
         end if;

         --  Set output stream

         Set_Output (Fd);
         return Fd;
      end if;
      return Invalid_FD;
   end Set_Output;

   --------------------
   -- Release_Output --
   --------------------

   procedure Release_Output (Fd : File_Descriptor) is
   begin
      if not Use_Stdout and then Fd /= Invalid_FD then
         Close (Fd);
         Set_Standard_Output;
      end if;
   end Release_Output;

end Outfiles;
