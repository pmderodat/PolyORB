--  A communication filter (a transport Data_Unit handler/forwarder).

--  $Id$

with Ada.Tags;
pragma Warnings (Off, Ada.Tags);
--  Only used within pragma Debug.
with Ada.Unchecked_Deallocation;

with PolyORB.Log;
pragma Elaborate_All (PolyORB.Log);

package body PolyORB.Components is

   use Ada.Tags;
   use PolyORB.Log;
   use Component_Seqs;

   package L is new PolyORB.Log.Facility_Log ("polyorb.components");
   procedure O (Message : in String; Level : Log_Level := Debug)
     renames L.Output;

   procedure Connect
     (Port : out Component_Access;
      Target : Component_Access) is
   begin
      Port := Target;
   end Connect;

   function Emit
     (Port : Component_Access;
      Msg    : Message'Class)
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

   procedure Emit_No_Reply
     (Port : Component_Access;
      Msg    : Message'Class)
   is
      Reply : constant Message'Class
        := Emit (Port, Msg);
      pragma Warnings (Off, Reply);
      --  Reply must be a Null_Message, and is ignored.
   begin
      pragma Assert (Reply in Null_Message);
      null;
   end Emit_No_Reply;

   procedure Destroy (C : in out Component_Access)
   is
      procedure Free is
         new Ada.Unchecked_Deallocation
        (Component'Class, Component_Access);
   begin
      pragma Debug
        (O ("Destroying component with allocation class "
            & C.Allocation_Class'Img));

      case C.Allocation_Class is
         when Dynamic =>
            Free (C);
         when others =>
            null;
      end case;
   end Destroy;

   procedure Set_Allocation_Class
     (C   : in out Component'Class;
      CAC : Component_Allocation_Class) is
   begin
      pragma Assert (C.Allocation_Class = Auto);
      C.Allocation_Class := CAC;
   end Set_Allocation_Class;

   procedure Subscribe
     (G      : in out Group;
      Target : Component_Access) is
   begin
      pragma Assert (Target /= null);
      Append (G.Members, Target);
   end Subscribe;

   procedure Unsubscribe
     (G      : in out Group;
      Target : Component_Access)
   is
      Members : constant Element_Array
        := To_Element_Array (G.Members);
   begin
      for I in Members'Range loop
         if Members (I) = Target then
            Delete (Source  => G.Members,
                    From    => 1 + I - Members'First,
                    Through => I + I - Members'First);
            return;
         end if;
      end loop;
   end Unsubscribe;

   function Handle_Message
     (Grp : access Multicast_Group;
      Msg : Message'Class)
     return Message'Class
   is
      Members : constant Element_Array
        := To_Element_Array (Grp.Members);
      Handled : Boolean := False;
      Nothing : Null_Message;
   begin
      for I in Members'Range loop
         begin
            Emit_No_Reply (Members (I), Msg);
            Handled := True;
         exception
            when Unhandled_Message =>
               null;
            when others =>
               raise;
         end;
      end loop;

      if Handled then
         return Nothing;
      else
         raise Unhandled_Message;
      end if;
   end Handle_Message;

   function Handle_Message
     (Grp : access Anycast_Group;
      Msg : Message'Class)
     return Message'Class
   is
      Members : constant Element_Array
        := To_Element_Array (Grp.Members);
   begin
      for I in Members'Range loop
         begin
            declare
               Reply : constant Message'Class
                 := Handle_Message (Members (I), Msg);
            begin
               return Reply;
            end;
         exception
            when Unhandled_Message =>
               null;
            when others =>
               raise;
         end;
      end loop;
      raise Unhandled_Message;
   end Handle_Message;

end PolyORB.Components;
