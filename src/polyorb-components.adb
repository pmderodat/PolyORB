------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                   P O L Y O R B . C O M P O N E N T S                    --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2001-2002 Free Software Foundation, Inc.           --
--                                                                          --
-- PolyORB is free software; you  can  redistribute  it and/or modify it    --
-- under terms of the  GNU General Public License as published by the  Free --
-- Software Foundation;  either version 2,  or (at your option)  any  later --
-- version. PolyORB is distributed  in the hope that it will be  useful,    --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License  for more details.  You should have received  a copy of the GNU  --
-- General Public License distributed with PolyORB; see file COPYING. If    --
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
--                PolyORB is maintained by ACT Europe.                      --
--                    (email: sales@act-europe.fr)                          --
--                                                                          --
------------------------------------------------------------------------------

--  A communication filter (a transport Data_Unit handler/forwarder).

--  $Id$

with Ada.Tags;
pragma Warnings (Off, Ada.Tags);
--  Only used within pragma Debug.
with Ada.Unchecked_Deallocation;

with PolyORB.Log;

package body PolyORB.Components is

   use Ada.Tags;
   use PolyORB.Log;
   use Component_Seqs;

   package L is new PolyORB.Log.Facility_Log ("polyorb.components");
   procedure O (Message : in String; Level : Log_Level := Debug)
     renames L.Output;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (C : in out Component) is
      pragma Warnings (Off);
      pragma Unreferenced (C);
      pragma Warnings (On);
   begin
      pragma Debug (O ("finalizing component"));
      null;
      --  Do nothing, as we actually always finalize types derived
      --  from Component.
   end Finalize;

   -------------
   -- Connect --
   -------------

   procedure Connect
     (Port   : out Component_Access;
      Target :     Component_Access) is
   begin
      Port := Target;
   end Connect;

   ----------
   -- Emit --
   ----------

   function Emit
     (Port : Component_Access;
      Msg  : Message'Class)
     return Message'Class
   is
      Res : constant Null_Message := (null record);
   begin
      if Port /= null then
         pragma Debug
           (O ("Sending message " & External_Tag (Msg'Tag)
               & " to target " & External_Tag (Port.all'Tag)));
         return Handle_Message (Port, Msg);
      else
         pragma Debug
           (O ("Message " & External_Tag (Msg'Tag)
               & " ignored (null target)"));
         return Res;
      end if;
   end Emit;

   -------------------
   -- Emit_No_Reply --
   -------------------

   procedure Emit_No_Reply
     (Port : Component_Access;
      Msg  : Message'Class)
   is
      Reply : constant Message'Class := Emit (Port, Msg);
      pragma Warnings (Off, Reply);
      --  Reply must be a Null_Message, and is ignored.
   begin
      pragma Assert (Reply in Null_Message);
      null;
   end Emit_No_Reply;

   -------------
   -- Destroy --
   -------------

   procedure Destroy (C : in out Component_Access)
   is
      procedure Free is
         new Ada.Unchecked_Deallocation
        (Component'Class, Component_Access);
   begin
      pragma Debug
        (O ("Destroying component with allocation class "
            & C.Allocation_Class'Img));
      pragma Assert (C /= null);

      case C.Allocation_Class is
         when Dynamic =>
            Finalize (C.all);
            Free (C);
         when others =>
            null;
      end case;
   end Destroy;

   --------------------------
   -- Set_Allocation_Class --
   --------------------------

   procedure Set_Allocation_Class
     (C   : in out Component'Class;
      CAC :        Component_Allocation_Class) is
   begin
      pragma Assert (C.Allocation_Class = Auto);
      C.Allocation_Class := CAC;
   end Set_Allocation_Class;

   ---------------
   -- Subscribe --
   ---------------

   procedure Subscribe
     (G      : in out Group;
      Target :        Component_Access) is
   begin
      pragma Assert (Target /= null);
      Append (G.Members, Target);
   end Subscribe;

   -----------------
   -- Unsubscribe --
   -----------------

   procedure Unsubscribe
     (G      : in out Group;
      Target : Component_Access)
   is
      Members : constant Element_Array := To_Element_Array (G.Members);

   begin
      for J in Members'Range loop
         if Members (J) = Target then
            Delete (Source  => G.Members,
                    From    => 1 + J - Members'First,
                    Through => J + J - Members'First);
            return;
         end if;
      end loop;
   end Unsubscribe;

   --------------------
   -- Handle_Message --
   --------------------

   function Handle_Message
     (Grp : access Multicast_Group;
      Msg : Message'Class)
     return Message'Class
   is
      Members : constant Element_Array := To_Element_Array (Grp.Members);
      Handled : Boolean := False;
      Nothing : Null_Message;

   begin
      for J in Members'Range loop
         begin
            Emit_No_Reply (Members (J), Msg);
            Handled := True;
         exception
            when Unhandled_Message =>
               null;
         end;
      end loop;

      if Handled then
         return Nothing;
      else
         raise Unhandled_Message;
      end if;
   end Handle_Message;

   --------------------
   -- Handle_Message --
   --------------------

   function Handle_Message
     (Grp : access Anycast_Group;
      Msg : Message'Class)
     return Message'Class
   is
      Members : constant Element_Array := To_Element_Array (Grp.Members);

   begin
      for J in Members'Range loop
         begin
            declare
               Reply : constant Message'Class
                 := Handle_Message (Members (J), Msg);
            begin
               return Reply;
            end;
         exception
            when Unhandled_Message =>
               null;
         end;
      end loop;
      raise Unhandled_Message;
   end Handle_Message;

end PolyORB.Components;
