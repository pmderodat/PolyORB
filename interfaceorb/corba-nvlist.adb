------------------------------------------------------------------------------
--                                                                          --
--                          ADABROKER COMPONENTS                            --
--                                                                          --
--                         C O R B A . N V L I S T                          --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                            $Revision: 1.3 $
--                                                                          --
--         Copyright (C) 1999-2000 ENST Paris University, France.           --
--                                                                          --
-- AdaBroker is free software; you  can  redistribute  it and/or modify it  --
-- under terms of the  GNU General Public License as published by the  Free --
-- Software Foundation;  either version 2,  or (at your option)  any  later --
-- version. AdaBroker  is distributed  in the hope that it will be  useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License  for more details.  You should have received  a copy of the GNU  --
-- General Public License distributed with AdaBroker; see file COPYING. If  --
-- not, write to the Free Software Foundation, 59 Temple Place - Suite 330, --
-- Boston, MA 02111-1307, USA.                                              --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
--             AdaBroker is maintained by ENST Paris University.            --
--                     (email: broker@inf.enst.fr)                          --
--                                                                          --
------------------------------------------------------------------------------

with AdaBroker.Debug;
pragma Elaborate_All (Adabroker.Debug);

package body CORBA.NVList is

   Flag : constant Natural
      := AdaBroker.Debug.Is_Active ("dynamic_proxy");
   procedure O is new AdaBroker.Debug.Output (Flag);

   --------------
   -- Add_Item --
   --------------

   procedure Add_Item
     (Self       : in out Object;
      Item_Name  : in     Identifier;
      Item       : in     Any;
      Item_Flags : in     Flags)
   is
      Nv : NamedValue;
   begin
      Nv := (Item_Name,
             Item,
             1, --  to do
             Item_Flags);
      Add_Item (Self, Nv);
   end Add_Item;

   --------------
   -- Add_Item --
   --------------

   procedure Add_Item
     (Self : in out Object;
      Item : in     NamedValue)
   is
      Tmp : Cell_Ptr := new Cell'(Item, Self.List);
   begin
      Self.List := Tmp;
      Self.Args_Count := Self.Args_Count + 1;
   end Add_Item;

   ---------------
   -- Get_Count --
   ---------------

   procedure Get_Count
     (Self : Object;
      Count : out CORBA.Long)
   is
   begin
      Count := Self.Args_Count;
   end Get_Count;

   --------------
   --  Revert  --
   --------------

   procedure Revert
     (Self : in out Object)
   is
      Tmp : Object := Null_Object;
      It  : Iterator;
   begin
      Start (It, Self);
      while not Done (It) loop
         Add_Item (Tmp, Get (It));
         Next (It);
      end loop;
      Self := Tmp;
   end Revert;

   ----------------
   --  Iterator  --
   ----------------

   procedure Start
     (I   : in out Iterator;
      Nvl : in     Object) is
   begin
      I.This := Nvl.List;
   end Start;

   function  Done
     (I   : in     Iterator)
      return CORBA.Boolean is
   begin
      return I.This = null;
   end Done;

   procedure Next
     (I   : in out Iterator) is
   begin
      I.This := I.This.Next;
   end Next;

   function Get
     (I   : in     Iterator)
      return CORBA.NamedValue is
   begin
      return I.This.Value;
   end Get;

   procedure Set_Argument
     (I   : in out Iterator;
      A   : in     CORBA.Any)
   is
   begin
      I.This.Value.Argument := A;
   end Set_Argument;


end CORBA.NVList;
