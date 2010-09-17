------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                  POLYORB.DNS.TRANSPORT_MECHANISMS.UDNS                   --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2005-2010, Free Software Foundation, Inc.          --
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

with PolyORB.Binding_Data.DNS.UDNS;
with PolyORB.Binding_Objects;
with PolyORB.ORB;
with PolyORB.Protocols.DNS.UDNS;
with PolyORB.Sockets;
with PolyORB.Transport.Datagram.Sockets;
with PolyORB.Filters;

package body PolyORB.DNS.Transport_Mechanisms.UDNS is

   use PolyORB.Components;
   use PolyORB.Errors;
   use PolyORB.Sockets;
   use PolyORB.Transport.Datagram.Sockets;
   use PolyORB.Utils.Sockets;

   ----------------
   -- Address_Of --
   ----------------

   function Address_Of
     (M : UDNS_Transport_Mechanism) return Utils.Sockets.Socket_Name
   is
   begin
      return M.Address.all;
   end Address_Of;

   --------------------
   -- Bind_Mechanism --
   --------------------

   --  Factories

   Pro : aliased PolyORB.Protocols.DNS.UDNS.UDNS_Protocol;
   UDNS_Factories : constant PolyORB.Filters.Factory_Array :=
                      (0 => Pro'Access);

   procedure Bind_Mechanism
     (Mechanism : UDNS_Transport_Mechanism;
      Profile   : access PolyORB.Binding_Data.Profile_Type'Class;
      The_ORB   : Components.Component_Access;
      QoS       : PolyORB.QoS.QoS_Parameters;
      BO_Ref    : out Smart_Pointers.Ref;
      Error     : out Errors.Error_Container)
   is
      pragma Unreferenced (QoS);

      use PolyORB.Binding_Data;
      use PolyORB.Binding_Objects;

      Sock        : Socket_Type;
      TE          : Transport.Transport_Endpoint_Access;

   begin
      if Profile.all
        not in PolyORB.Binding_Data.DNS.UDNS.UDNS_Profile_Type then
         Throw (Error, Comm_Failure_E,
                System_Exception_Members'
                (Minor => 0, Completed => Completed_Maybe));
         return;
      end if;

      Create_Socket (Socket => Sock,
                     Family => Family_Inet,
                     Mode   => Socket_Datagram);

      Set_Socket_Option
        (Sock,
         Socket_Level, (Reuse_Address, True));

      TE := new Socket_Endpoint;
      Create
        (Socket_Endpoint (TE.all),
         Sock,
         To_Address (Mechanism.Address.all));

      Binding_Objects.Setup_Binding_Object
        (The_ORB,
         TE,
         UDNS_Factories,
         BO_Ref,
         Profile_Access (Profile));

      ORB.Register_Binding_Object
        (ORB.ORB_Access (The_ORB),
         BO_Ref,
         ORB.Client);

   exception
      when Sockets.Socket_Error =>
         Throw (Error, Comm_Failure_E, System_Exception_Members'
                (Minor => 0, Completed => Completed_Maybe));
   end Bind_Mechanism;

   --------------------
   -- Create_Factory --
   --------------------

   procedure Create_Factory
     (MF  : out UDNS_Transport_Mechanism_Factory;
      TAP : Transport.Transport_Access_Point_Access)
   is
   begin
      MF.Address :=
        new Socket_Name'(Address_Of (Socket_Access_Point (TAP.all)));
   end Create_Factory;

   --------------------------------
   -- Create_Transport_Mechanism --
   --------------------------------

   function Create_Transport_Mechanism
     (MF : UDNS_Transport_Mechanism_Factory) return Transport_Mechanism_Access
   is
      Result  : constant Transport_Mechanism_Access :=
                  new UDNS_Transport_Mechanism;
      TResult : UDNS_Transport_Mechanism
                  renames UDNS_Transport_Mechanism (Result.all);

   begin
      TResult.Address := new Socket_Name'(MF.Address.all);
      return Result;
   end Create_Transport_Mechanism;

   function Create_Transport_Mechanism
     (Address : Utils.Sockets.Socket_Name) return Transport_Mechanism_Access
   is
      Result  : constant Transport_Mechanism_Access :=
                  new UDNS_Transport_Mechanism;
      TResult : UDNS_Transport_Mechanism
                  renames UDNS_Transport_Mechanism (Result.all);
   begin
      TResult.Address := new Socket_Name'(Address);
      return Result;
   end Create_Transport_Mechanism;

   ------------------------
   -- Is_Local_Mechanism --
   ------------------------

   function Is_Local_Mechanism
     (MF : access UDNS_Transport_Mechanism_Factory;
      M  : access Transport_Mechanism'Class)
      return Boolean is
   begin
      return M.all in UDNS_Transport_Mechanism
               and then
             UDNS_Transport_Mechanism (M.all).Address.all = MF.Address.all;
   end Is_Local_Mechanism;

   ----------------------
   -- Release_Contents --
   ----------------------

   procedure Release_Contents (M : access UDNS_Transport_Mechanism) is
   begin
      Free (M.Address);
   end Release_Contents;

   ---------------
   -- Duplicate --
   ---------------

   function Duplicate
     (TMA : UDNS_Transport_Mechanism) return UDNS_Transport_Mechanism
   is
   begin
      return UDNS_Transport_Mechanism'
               (Address => new Socket_Name'(TMA.Address.all));
   end Duplicate;

   ------------------
   -- Is_Colocated --
   ------------------

   function Is_Colocated
     (Left  : UDNS_Transport_Mechanism;
      Right : Transport_Mechanism'Class) return Boolean
   is
   begin
      return Right in UDNS_Transport_Mechanism
        and then Left.Address = UDNS_Transport_Mechanism (Right).Address;
   end Is_Colocated;

end PolyORB.DNS.Transport_Mechanisms.UDNS;