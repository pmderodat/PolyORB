------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--            P O L Y O R B . B I N D I N G _ D A T A . S O A P             --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2001-2003 Free Software Foundation, Inc.           --
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

--  Binding data concrete implementation for SOAP over HTTP.

--  $Id$

with Ada.Streams;

with PolyORB.Filters.HTTP;
with PolyORB.Initialization;
pragma Elaborate_All (PolyORB.Initialization); --  WAG:3.15

with PolyORB.ORB.Interface;
with PolyORB.Parameters;
with PolyORB.Protocols;
with PolyORB.Protocols.SOAP_Pr;
with PolyORB.Setup;

with PolyORB.References.IOR;
with PolyORB.References.URI;
with PolyORB.Representations.CDR;
--  XXX Unfortunate dependency on CDR code. Should provide
--  To_Any methods instead!!!!!! (but actually the Any in question
--  would be specific of how IORs are constructed) (but we could
--  say that the notion of IOR is cross-platform!).

with PolyORB.Transport.Connected.Sockets;
with PolyORB.Utils.Strings;
with PolyORB.Utils.Sockets;
with PolyORB.Log;

with AWS.URL;

package body PolyORB.Binding_Data.SOAP is

   use Ada.Streams;

   use PolyORB.Log;
   use PolyORB.Buffers;
   use PolyORB.Filters.HTTP;
   use PolyORB.Objects;
   use PolyORB.Protocols.SOAP_Pr;
   use PolyORB.Representations.CDR;
   use PolyORB.Transport;
   use PolyORB.Transport.Connected.Sockets;
   use PolyORB.Types;

   package L is new PolyORB.Log.Facility_Log ("polyorb.binding_data.soap");
   procedure O (Message : in Standard.String; Level : Log_Level := Debug)
     renames L.Output;


   Preference : Profile_Preference;
   --  Global variable: the preference to be returned
   --  by Get_Profile_Preference for SOAP profiles.

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (P : in out SOAP_Profile_Type) is
   begin
      P.Object_Id := null;
   end Initialize;

   ------------
   -- Adjust --
   ------------

   procedure Adjust (P : in out SOAP_Profile_Type) is
   begin
      if P.Object_Id /= null then
         P.Object_Id := new Object_Id'(P.Object_Id.all);
      end if;
   end Adjust;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (P : in out SOAP_Profile_Type) is
   begin
      Free (P.Object_Id);
   end Finalize;

   ------------------
   -- Bind_Profile --
   ------------------

   function Bind_Profile
     (Profile : SOAP_Profile_Type;
      The_ORB : Components.Component_Access)
     return Components.Component_Access
   is
      use PolyORB.Components;
      use PolyORB.ORB;
      use PolyORB.Protocols;
      use PolyORB.Sockets;
      use PolyORB.Filters;

      Sock : Socket_Type;
      Remote_Addr : Sock_Addr_Type := Profile.Address;
      Pro  : aliased SOAP_Protocol;
      Htt  : aliased HTTP_Filter_Factory;
      TE   : constant Transport.Transport_Endpoint_Access :=
        new Socket_Endpoint;
      Filter : Filter_Access;
   begin
      Create_Socket (Sock);
      Connect_Socket (Sock, Remote_Addr);
      Create (Socket_Endpoint (TE.all), Sock);

      Chain_Factories ((0 => Htt'Unchecked_Access,
                        1 => Pro'Unchecked_Access));

      Filter := HTTP.Create_Filter_Chain (Htt'Unchecked_Access);
      --  Filter must be an access to the lowest filter in
      --  the stack (the HTTP filter in the case of SOAP/HTTP).

      ORB.Register_Endpoint
        (ORB_Access (The_ORB),
         TE,
         Filter,
         ORB.Client);
      --  Register the endpoint and lowest filter with the ORB.

      return Component_Access (Upper (Filter));
   end Bind_Profile;

   ---------------------
   -- Get_Profile_Tag --
   ---------------------

   function Get_Profile_Tag
     (Profile : SOAP_Profile_Type)
     return Profile_Tag
   is
      pragma Warnings (Off);
      pragma Unreferenced (Profile);
      pragma Warnings (On);

   begin
      return Tag_SOAP;
   end Get_Profile_Tag;

   ----------------------------
   -- Get_Profile_Preference --
   ----------------------------

   function Get_Profile_Preference
     (Profile : SOAP_Profile_Type)
     return Profile_Preference
   is
      pragma Warnings (Off);
      pragma Unreferenced (Profile);
      pragma Warnings (On);
   begin
      return Preference;
   end Get_Profile_Preference;

   ------------------
   -- Get_URI_Path --
   ------------------

   function Get_URI_Path
     (Profile : SOAP_Profile_Type)
     return Types.String is
   begin
      return Profile.URI_Path;
   end Get_URI_Path;

   --------------------
   -- Create_Factory --
   --------------------

   procedure Create_Factory
     (PF : out SOAP_Profile_Factory;
      TAP : Transport.Transport_Access_Point_Access;
      ORB : PolyORB.Components.Component_Access)
   is
      pragma Warnings (Off);
      pragma Unreferenced (ORB);
      pragma Warnings (On);

   begin
      PF.Address := Address_Of (Socket_Access_Point (TAP.all));
   end Create_Factory;

   --------------------
   -- Create_Profile --
   --------------------

   function Create_Profile
     (PF  : access SOAP_Profile_Factory;
      Oid : Objects.Object_Id)
     return Profile_Access
   is
      use PolyORB.Transport.Connected.Sockets;

      Result : constant Profile_Access :=
        new SOAP_Profile_Type;

      TResult : SOAP_Profile_Type
        renames SOAP_Profile_Type (Result.all);

   begin
      TResult.Object_Id := new Object_Id'(Oid);
      TResult.Address   := PF.Address;

      declare
         Oid_Translate : constant ORB.Interface.Oid_Translate :=
           (PolyORB.Components.Message with Oid => TResult.Object_Id);

         M : constant PolyORB.Components.Message'Class :=
           PolyORB.Components.Emit
           (Port => Components.Component_Access (Setup.The_ORB),
            Msg  => Oid_Translate);

         TM : ORB.Interface.URI_Translate renames
           ORB.Interface.URI_Translate (M);
      begin
         TResult.URI_Path := TM.Path;
      end;

      return  Result;
   end Create_Profile;

   function Create_Profile
     (URI : Types.String)
     return Profile_Access
   is
      use AWS.URL;
      use Sockets;

      URL : AWS.URL.Object :=
        Parse (To_Standard_String (URI));

      Result : constant Profile_Access := new SOAP_Profile_Type;

      TResult : SOAP_Profile_Type
        renames SOAP_Profile_Type (Result.all);
   begin
      Normalize (URL);
      begin
         TResult.Address.Addr := Inet_Addr (Server_Name (URL));
      exception
         when Socket_Error =>
            TResult.Address.Addr :=
              Addresses (Get_Host_By_Name (Server_Name (URL)), 1);
      end;

      TResult.Address.Port := Port_Type (Positive'(Port (URL)));

      TResult.URI_Path := To_PolyORB_String (AWS.URL.URI (URL));

      if ORB.Is_Profile_Local (Setup.The_ORB, Result) then

         --  Fill Oid from URI for a local profile.

         declare
            URI_Translate : constant ORB.Interface.URI_Translate :=
              (PolyORB.Components.Message with Path => TResult.URI_Path);

            M : constant PolyORB.Components.Message'Class :=
              PolyORB.Components.Emit
              (Port => Components.Component_Access (Setup.The_ORB),
               Msg  => URI_Translate);

            TM : ORB.Interface.Oid_Translate renames
              ORB.Interface.Oid_Translate (M);
         begin
            TResult.Object_Id := TM.Oid;
         end;
      end if;

      return Result;
   end Create_Profile;

   ----------------------
   -- Is_Local_Profile --
   ----------------------

   function Is_Local_Profile
     (PF : access SOAP_Profile_Factory;
      P  : access Profile_Type'Class)
      return Boolean
   is
      use type PolyORB.Sockets.Sock_Addr_Type;
   begin
      return P.all in SOAP_Profile_Type
        and then SOAP_Profile_Type (P.all).Address = PF.Address;
   end Is_Local_Profile;

   --------------------------------
   -- Marshall_SOAP_Profile_Body --
   --------------------------------

   procedure Marshall_SOAP_Profile_Body
     (Buf     : access Buffer_Type;
      Profile : Profile_Access)
   is
      use PolyORB.Utils.Sockets;
      use PolyORB.Buffers;

      SOAP_Profile : SOAP_Profile_Type renames SOAP_Profile_Type (Profile.all);
      Profile_Body : Buffer_Access := new Buffer_Type;

   begin

      --  A Tag_SOAP Profile Body is an encapsulation.

      Start_Encapsulation (Profile_Body);

      --  Marshalling the socket address

      Marshall_Socket (Profile_Body, SOAP_Profile.Address);

      --  Marshalling the Object Id

      Marshall
        (Profile_Body, Stream_Element_Array
         (SOAP_Profile.Object_Id.all));

      Marshall (Profile_Body, SOAP_Profile.URI_Path);

      --  Marshall the Profile_Body into IOR.

      Marshall (Buf, Encapsulate (Profile_Body));
      Release (Profile_Body);
   end Marshall_SOAP_Profile_Body;

   ----------------------------------
   -- Unmarshall_SOAP_Profile_Body --
   ----------------------------------

   function Unmarshall_SOAP_Profile_Body
     (Buffer       : access Buffer_Type)
     return Profile_Access
   is
      use PolyORB.Utils.Sockets;

      Profile_Body   : aliased Encapsulation := Unmarshall (Buffer);
      Profile_Buffer : Buffer_Access := new Buffers.Buffer_Type;
      Result         : constant Profile_Access := new SOAP_Profile_Type;
      TResult        : SOAP_Profile_Type
        renames SOAP_Profile_Type (Result.all);
   begin

      --  A Tag_SOAP Profile Body is an encapsulation.

      Decapsulate (Profile_Body'Access, Profile_Buffer);

      --  Unmarshalling the socket address

      Unmarshall_Socket (Profile_Buffer, TResult.Address);

      --  Unmarshalling the Object Id

      declare
         Str  : aliased constant Stream_Element_Array :=
           Unmarshall (Profile_Buffer);
      begin
         TResult.Object_Id := new Object_Id'(Object_Id (Str));
      end;

      TResult.URI_Path := Unmarshall (Profile_Buffer);
      Release (Profile_Buffer);

      return Result;
   end Unmarshall_SOAP_Profile_Body;

   --------------------
   -- Profile_To_URI --
   --------------------

   function Profile_To_URI
     (P : Profile_Access)
     return Types.String
   is
      use PolyORB.Types;
      use PolyORB.Sockets;
      use PolyORB.Utils;
      use PolyORB.Utils.Strings;

      SOAP_Profile : SOAP_Profile_Type renames SOAP_Profile_Type (P.all);
   begin
      pragma Debug (O ("SOAP Profile to URI"));
      return SOAP_URI_Prefix
        & Image (SOAP_Profile.Address.Addr) & ":"
        & Trimmed_Image (Integer (SOAP_Profile.Address.Port))
        & SOAP_Profile.URI_Path;
   end Profile_To_URI;

   --------------------
   -- URI_To_Profile --
   --------------------

   function URI_To_Profile
     (Str : Types.String)
     return Profile_Access
   is
      use PolyORB.Types;
      use PolyORB.Utils;
      use PolyORB.Utils.Strings;
      use PolyORB.Utils.Sockets;

      Len    : constant Integer := Length (SOAP_URI_Prefix);
   begin
      if Length (Str) > Len
        and then To_String (Str) (1 .. Len) = SOAP_URI_Prefix then
         declare
            Result  : constant Profile_Access := new SOAP_Profile_Type;
            TResult : SOAP_Profile_Type renames SOAP_Profile_Type (Result.all);
            S       : constant String
              := To_Standard_String (Str) (Len + 1 .. Length (Str));
            Index   : Integer := S'First;
            Index2  : Integer;
         begin
            pragma Debug (O ("SOAP URI to profile: enter"));

            Index2 := Find (S, Index, ':');
            if Index2 = S'Last + 1 then
               return null;
            end if;
            pragma Debug (O ("Address = " & S (Index .. Index2 - 1)));
            TResult.Address.Addr := String_To_Addr
              (To_PolyORB_String (S (Index .. Index2 - 1)));
            Index := Index2 + 1;

            Index2 := Find (S, Index, '/');
            if Index2 = S'Last + 1 then
               return null;
            end if;
            pragma Debug (O ("Port = " & S (Index .. Index2 - 1)));
            TResult.Address.Port :=
              PolyORB.Sockets.Port_Type'Value (S (Index .. Index2 - 1));
            Index := Index2;
            TResult.URI_Path := To_PolyORB_String (S (Index .. S'Last));

            pragma Debug (O ("URI_Path is " & S (Index .. S'Last)));
            pragma Debug (O ("SOAP URI to profile: leave"));
            return Result;
         end;
      else
         return null;
      end if;
   end URI_To_Profile;


   -----------
   -- Image --
   -----------

   function Image (Prof : SOAP_Profile_Type) return String
   is
      Result : PolyORB.Types.String := To_PolyORB_String
        ("Address: " & Sockets.Image (Prof.Address));
   begin
      if Prof.Object_Id /= null then
         Append
           (Result,
            ", Object_Id : " & PolyORB.Objects.Image
            (Prof.Object_Id.all));
      else
         Append (Result, ", object id not available.");
      end if;
      return To_Standard_String (Result);
   end Image;

   ------------
   -- To_URI --
   ------------

   function To_URI (Prof : SOAP_Profile_Type) return String is
   begin
      return "http://" & Sockets.Image (Prof.Address)
        & To_Standard_String (Prof.URI_Path);
   end To_URI;

   ------------
   -- Get_OA --
   ------------

   function Get_OA
     (Profile : SOAP_Profile_Type)
     return PolyORB.Smart_Pointers.Entity_Ptr
   is
      pragma Warnings (Off); --  WAG:3.15
      pragma Unreferenced (Profile);
      pragma Warnings (On); --  WAG:3.15
   begin
      return PolyORB.Smart_Pointers.Entity_Ptr
        (PolyORB.ORB.Object_Adapter (PolyORB.Setup.The_ORB));
   end Get_OA;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize;

   procedure Initialize
   is
      use PolyORB.References.URI;

      Preference_Offset : constant String :=
        PolyORB.Parameters.Get_Conf
        (Section => "soap",
         Key     => "polyorb.binding_data.soap.preference",
         Default => "0");
   begin
      Preference := Preference_Default + Profile_Preference'Value
        (Preference_Offset);
      References.IOR.Register
        (Tag_SOAP,
         Marshall_SOAP_Profile_Body'Access,
         Unmarshall_SOAP_Profile_Body'Access);
      References.URI.Register
        (Tag_SOAP,
         SOAP_URI_Prefix,
         Profile_To_URI'Access,
         URI_To_Profile'Access);
   end Initialize;

   use PolyORB.Initialization;
   use PolyORB.Initialization.String_Lists;
   use PolyORB.Utils.Strings;

begin
   Register_Module
     (Module_Info'
      (Name      => +"binding_data.soap",
       Conflicts => Empty,
       Depends   => +"sockets",
       Provides  => +"binding_factories",
       Implicit  => False,
       Init      => Initialize'Access));
end PolyORB.Binding_Data.SOAP;
