------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--              COSNOTIFYCHANNELADMIN.EVENTCHANNELFACTORY.IMPL              --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--            Copyright (C) 2003 Free Software Foundation, Inc.             --
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

with CORBA.Impl;
pragma Warnings (Off, CORBA.Impl);

with CosNotifyChannelAdmin.EventChannel.Impl;

with CosNotifyChannelAdmin.EventChannelFactory.Helper;
pragma Elaborate (CosNotifyChannelAdmin.EventChannelFactory.Helper);
pragma Warnings (Off, CosNotifyChannelAdmin.EventChannelFactory.Helper);

with CosNotifyChannelAdmin.EventChannelFactory.Skel;
pragma Elaborate (CosNotifyChannelAdmin.EventChannelFactory.Skel);
pragma Warnings (Off, CosNotifyChannelAdmin.EventChannelFactory.Skel);

with PortableServer;

with PolyORB.CORBA_P.Server_Tools;
with PolyORB.Tasking.Mutexes;
--  with PolyORB.Tasking.Semaphores;
with PolyORB.Log;

package body CosNotifyChannelAdmin.EventChannelFactory.Impl is

   use IDL_SEQUENCE_CosNotifyChannelAdmin_ChannelID;

   use PortableServer;

   use PolyORB.CORBA_P.Server_Tools;
   use PolyORB.Tasking.Mutexes;
   --  use PolyORB.Tasking.Semaphores;

   use PolyORB.Log;
   package L is new PolyORB.Log.Facility_Log ("eventchannelfactory");
   procedure O (Message : in Standard.String; Level : Log_Level := Debug)
     renames L.Output;

   package EventChannels is
      new CORBA.Sequences.Unbounded (CosNotifyChannelAdmin.EventChannel.Ref);

   type Event_Channel_Factory_Record is record
      Channels : EventChannels.Sequence;
      IDSeq    : CosNotifyChannelAdmin.ChannelIDSeq;
      This     : Object_Ptr;
   end record;

   ---------------------------
   -- Ensure_Initialization --
   ---------------------------

   procedure Ensure_Initialization;
   pragma Inline (Ensure_Initialization);
   --  Ensure that the Mutexes are initialized

   T_Initialized : Boolean := False;
   Self_Mutex : Mutex_Access;

   procedure Ensure_Initialization is
   begin
      if not T_Initialized then
         Create (Self_Mutex);
         T_Initialized := True;
      end if;
   end Ensure_Initialization;

   --------------------
   -- Create_Channel --
   --------------------

   procedure Create_Channel
      (Self          : access Object;
       Initial_QoS   : in CosNotification.QoSProperties;
       Initial_Admin : in CosNotification.AdminProperties;
       Id            : out ChannelID;
       Returns       : out CosNotifyChannelAdmin.EventChannel.Ref)
   is
      Channel : CosNotifyChannelAdmin.EventChannel.Impl.Object_Ptr;
      My_Ref  : CosNotifyChannelAdmin.EventChannelFactory.Ref;
   begin
      pragma Debug (O ("create_channel in eventchannelfactory"));

      Ensure_Initialization;

      Enter (Self_Mutex);
      Servant_To_Reference (Servant (Self.X.This), My_Ref);
      Channel := CosNotifyChannelAdmin.EventChannel.Impl.Create
                 (My_Ref, Initial_QoS, Initial_Admin);
      Servant_To_Reference (Servant (Channel), Returns);

      EventChannels.Append (Self.X.Channels, Returns);
      Id := CosNotifyChannelAdmin.ChannelID
            (EventChannels.Length (Self.X.Channels));
      Append (Self.X.IDSeq, Id);

      Leave (Self_Mutex);

   end Create_Channel;

   ----------------------
   -- Get_All_Channels --
   ----------------------

   function Get_All_Channels
     (Self : access Object)
     return CosNotifyChannelAdmin.ChannelIDSeq
   is
      MyChannelSeq : CosNotifyChannelAdmin.ChannelIDSeq;
   begin
      pragma Debug (O ("get_all_channels from eventchannelfactory"));
      Ensure_Initialization;

      Enter (Self_Mutex);
      MyChannelSeq := Self.X.IDSeq;
      Leave (Self_Mutex);

      return MyChannelSeq;
   end Get_All_Channels;

   -----------------------
   -- Get_Event_Channel --
   -----------------------

   function Get_Event_Channel
     (Self : access Object;
      Id   : in ChannelID)
     return CosNotifyChannelAdmin.EventChannel.Ref
   is
      MyChannel : CosNotifyChannelAdmin.EventChannel.Ref;
      SeqLen    : CosNotifyChannelAdmin.ChannelID;
   begin
      pragma Debug (O ("get_event_channel from eventchannelfactory"));

      Ensure_Initialization;

      Enter (Self_Mutex);
      SeqLen := CosNotifyChannelAdmin.ChannelID (Length (Self.X.IDSeq));

      if Id > SeqLen then
         raise ChannelNotFound;
      end if;

      MyChannel := EventChannels.Get_Element (Self.X.Channels, Integer (Id));
      Leave (Self_Mutex);

      return MyChannel;
   end Get_Event_Channel;

   ------------
   -- Create --
   ------------

   function Create
      return Object_Ptr
   is
      Factory : Object_Ptr;
      My_Ref  : CosNotifyChannelAdmin.EventChannelFactory.Ref;
   begin
      pragma Debug (O ("create eventchannelfactory"));

      Factory         := new Object;
      Factory.X       := new Event_Channel_Factory_Record;
      Factory.X.This  := Factory;
      Initiate_Servant (Servant (Factory), My_Ref);

      return Factory;
   end Create;

end CosNotifyChannelAdmin.EventChannelFactory.Impl;