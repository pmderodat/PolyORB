------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                   A D A _ B E . I D E N T I F I E R S                    --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2001-2005 Free Software Foundation, Inc.           --
--                                                                          --
-- PolyORB is free software; you  can  redistribute  it and/or modify it    --
-- under terms of the  GNU General Public License as published by the  Free --
-- Software Foundation;  either version 2,  or (at your option)  any  later --
-- version. PolyORB is distributed  in the hope that it will be  useful,    --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License  for more details.  You should have received  a copy of the GNU  --
-- General Public License distributed with PolyORB; see file COPYING. If    --
-- not, write to the Free Software Foundation, 51 Franklin Street, Fifth    --
-- Floor, Boston, MA 02111-1301, USA.                                       --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
--                  PolyORB is maintained by AdaCore                        --
--                     (email: sales@adacore.com)                           --
--                                                                          --
------------------------------------------------------------------------------

with Utils; use Utils;

with Idl_Fe.Tree; use Idl_Fe.Tree;
with Idl_Fe.Tree.Synthetic; use Idl_Fe.Tree.Synthetic;

with Ada_Be.Debug;
pragma Elaborate_All (Ada_Be.Debug);

package body Ada_Be.Identifiers is

   Flag : constant Natural
     := Ada_Be.Debug.Is_Active ("ada_be.identifiers");
   procedure O is new Ada_Be.Debug.Output (Flag);

   -------------------
   -- Ada_Full_Name --
   -------------------

   function Ada_Full_Name (Node : Node_Id) return String is
   begin
      pragma Debug
        (O ("Ada_Full_Name: enter (Node = " & Img (Node)
            & ", Kind = " & Img (Kind (Node)) & ")"));

      case Kind (Node) is
         when K_Scoped_Name =>
            return Ada_Full_Name (Value (Node));

         when K_Ben_Idl_File =>
            return Ada_Name (Node);

         when K_Repository =>
            raise Program_Error;

         when others =>
            declare
               P_Node    : constant Node_Id := Parent_Scope (Node);
               Node_Name : constant String  := Ada_Name (Node);
            begin
               pragma Assert (Kind (P_Node) /= K_Repository);

               if Kind (P_Node) = K_Ben_Idl_File
                 and then Is_Gen_Scope (Node)
               then
                  return Node_Name;
               else
                  return Ada_Full_Name (P_Node) & "." & Node_Name;
               end if;
            end;
      end case;
   end Ada_Full_Name;

   --------------
   -- Ada_Name --
   --------------

   function Ada_Name (Node : Node_Id) return String is
      Result : String
        := Name (Node);
      First : Integer := Result'First;
      NK : constant Node_Kind
        := Kind (Node);
   begin
      while First <= Result'Last
        and then Result (First) = '_' loop
         First := First + 1;
      end loop;

      if NK = K_Operation
        and then Original_Node (Node) /= No_Node
        and then Kind (Original_Node (Node)) = K_Attribute
      then
         if Result (First) = 'g' then
            Result (First) := 'G';
         elsif Result (First) = 's' then
            Result (First) := 'S';
         else
            raise Program_Error;
         end if;
      end if;

      for J in First .. Result'Last loop
         if Result (J) = '_'
           and then J < Result'Last
           and then Result (J + 1) = '_' then
            Result (J + 1) := 'U';
         end if;
      end loop;

      if False
        or else NK = K_Forward_Interface
        or else NK = K_Forward_ValueType
      then
         return Result (First .. Result'Last) & "_Forward";
      else
         return Result (First .. Result'Last);
      end if;
   end Ada_Name;

   function Parent_Scope_Name
     (Node : Node_Id)
     return String is
   begin
      pragma Debug (O ("Parent_Scope_Name : enter & end"));
      pragma Debug (O ("Parent_Scope_Name : node kind is "
                       & Node_Kind'Image (Kind (Node))));
      return Ada_Full_Name (Parent_Scope (Node));
   end Parent_Scope_Name;

end Ada_Be.Identifiers;