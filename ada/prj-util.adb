------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                              P R J . U T I L                             --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                            $Revision$                              --
--                                                                          --
--             Copyright (C) 2000 Free Software Foundation, Inc.            --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- It is now maintained by Ada Core Technologies Inc (http://www.gnat.com). --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Unchecked_Deallocation;

with Namet;    use Namet;
with Osint;
with Stringt;  use Stringt;

package body Prj.Util is

   procedure Free is new Ada.Unchecked_Deallocation
     (Text_File_Data, Text_File);

   -----------
   -- Close --
   -----------

   procedure Close (File : in out Text_File) is
   begin
      if File = null then
         Osint.Fail ("Close attempted on an invalid Text_File");
      end if;

      Close (File.FD);
      Free (File);
   end Close;

   -----------------
   -- End_Of_File --
   -----------------

   function End_Of_File (File : Text_File) return Boolean is
   begin
      if File = null then
         Osint.Fail ("End_Of_File attempted on an invalid Text_File");
      end if;

      return File.End_Of_File_Reached;
   end End_Of_File;

   --------------
   -- Get_Line --
   --------------

   procedure Get_Line
     (File : Text_File;
      Line : out String;
      Last : out Natural)
   is
      C : Character;

      procedure Advance;

      -------------
      -- Advance --
      -------------

      procedure Advance is
      begin
         if File.Cursor = File.Buffer_Len then
            if File.Buffer_Len < File.Buffer'Length then
               File.End_Of_File_Reached := True;
               return;

            else
               File.Buffer_Len :=
                 Read
                  (FD => File.FD,
                   A  => File.Buffer'Address,
                   N  => File.Buffer'Length);

               if File.Buffer_Len = 0 then
                  File.End_Of_File_Reached := True;
                  return;
               else
                  File.Cursor := 1;
               end if;
            end if;

         else
            File.Cursor := File.Cursor + 1;
         end if;
      end Advance;

   --  Start of processing for Get_Line

   begin
      if File = null then
         Osint.Fail ("Get_Line attempted on an invalid Text_File");
      end if;

      Last := Line'First - 1;

      if not File.End_Of_File_Reached then
         loop
            C := File.Buffer (File.Cursor);
            exit when C = ASCII.CR or else C = ASCII.LF;
            Last := Last + 1;
            Line (Last) := C;
            Advance;

            if File.End_Of_File_Reached then
               return;
            end if;

            exit when Last = Line'Last;
         end loop;

         if C = ASCII.CR or else C = ASCII.LF then
            Advance;

            if File.End_Of_File_Reached then
               return;
            end if;
         end if;

         if C = ASCII.CR
           and then File.Buffer (File.Cursor) = ASCII.LF
         then
            Advance;
         end if;
      end if;
   end Get_Line;

   --------------
   -- Is_Valid --
   --------------

   function Is_Valid (File : Text_File) return Boolean is
   begin
      return File /= null;
   end Is_Valid;

   ----------
   -- Open --
   ----------

   procedure Open (File : out Text_File; Name : in String) is
      FD        : File_Descriptor;
      File_Name : String (1 .. Name'Length + 1);

   begin
      File_Name (1 .. Name'Length) := Name;
      File_Name (File_Name'Last) := ASCII.NUL;
      FD := Open_Read (Name => File_Name'Address,
                            Fmode => GNAT.OS_Lib.Text);
      if FD = Invalid_FD then
         File := null;
      else
         File := new Text_File_Data;
         File.FD := FD;
         File.Buffer_Len :=
           Read (FD => FD,
                 A  => File.Buffer'Address,
                 N  => File.Buffer'Length);

         if File.Buffer_Len = 0 then
            File.End_Of_File_Reached := True;
         else
            File.Cursor := 1;
         end if;
      end if;
   end Open;

   --------------
   -- Value_Of --
   --------------

   function Value_Of
     (Index    : Name_Id;
      In_Array : Array_Element_Id)
      return     Name_Id
   is
      Current : Array_Element_Id := In_Array;
      Element : Array_Element;

   begin
      while Current /= No_Array_Element loop
         Element := Array_Elements.Table (Current);

         if Index = Element.Index then
            exit when Element.Value.Kind /= Single;
            exit when String_Length (Element.Value.Value) = 0;
            String_To_Name_Buffer (Element.Value.Value);
            return Name_Find;
         else
            Current := Element.Next;
         end if;
      end loop;

      return No_Name;
   end Value_Of;

   function Value_Of
     (Index    : Name_Id;
      In_Array : Array_Element_Id)
      return     Variable_Value
   is
      Current : Array_Element_Id := In_Array;
      Element : Array_Element;

   begin
      while Current /= No_Array_Element loop
         Element := Array_Elements.Table (Current);

         if Index = Element.Index then
            return Element.Value;
         else
            Current := Element.Next;
         end if;
      end loop;

      return Nil_Variable_Value;
   end Value_Of;

   function Value_Of
     (Name                   : Name_Id;
      Variable_Or_Array_Name : Name_Id;
      In_Package             : Package_Id)
      return                   Variable_Value
   is
      The_Array    : Array_Element_Id;
      The_Variable : Variable_Value := Nil_Variable_Value;

   begin
      if In_Package /= No_Package then

         --  First, look if there is an array element that fits

         The_Array :=
           Value_Of
             (Name      => Variable_Or_Array_Name,
              In_Arrays => Packages.Table (In_Package).Decl.Arrays);
         The_Variable :=
           Value_Of
             (Index    => Name,
              In_Array => The_Array);

         --  If there is no array element, look for a variable

         if The_Variable = Nil_Variable_Value then
            The_Variable :=
              Value_Of
                (Variable_Name => Variable_Or_Array_Name,
                 In_Variables  => Packages.Table (In_Package).Decl.Variables);
         end if;
      end if;

      return The_Variable;
   end Value_Of;

   function Value_Of
     (Index     : Name_Id;
      In_Array  : Name_Id;
      In_Arrays : Array_Id)
      return      Name_Id
   is
      Current : Array_Id := In_Arrays;
      The_Array : Array_Data;

   begin
      while Current /= No_Array loop
         The_Array := Arrays.Table (Current);
         if The_Array.Name = In_Array then
            return Value_Of (Index, In_Array => The_Array.Value);
         else
            Current := The_Array.Next;
         end if;
      end loop;

      return No_Name;
   end Value_Of;

   function Value_Of
     (Name      : Name_Id;
      In_Arrays : Array_Id)
      return      Array_Element_Id
   is
      Current : Array_Id := In_Arrays;
      The_Array : Array_Data;

   begin
      while Current /= No_Array loop
         The_Array := Arrays.Table (Current);
         if The_Array.Name = Name then
            return The_Array.Value;
         else
            Current := The_Array.Next;
         end if;
      end loop;

      return No_Array_Element;
   end Value_Of;

   function Value_Of
     (Name        : Name_Id;
      In_Packages : Package_Id)
      return        Package_Id
   is
      Current : Package_Id := In_Packages;
      The_Package : Package_Element;

   begin
      while Current /= No_Package loop
         The_Package := Packages.Table (Current);
         exit when The_Package.Name /= No_Name and then
           The_Package.Name = Name;
         Current := The_Package.Next;
      end loop;

      return Current;
   end Value_Of;

   function Value_Of
     (Variable_Name : Name_Id;
      In_Variables  : Variable_Id)
      return          Variable_Value
   is
      Current : Variable_Id := In_Variables;
      The_Variable : Variable;

   begin
      while Current /= No_Variable loop
         The_Variable := Variable_Elements.Table (Current);

         if Variable_Name = The_Variable.Name then
            return The_Variable.Value;
         else
            Current := The_Variable.Next;
         end if;
      end loop;

      return Nil_Variable_Value;
   end Value_Of;

end Prj.Util;
