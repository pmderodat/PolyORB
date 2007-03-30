------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                P O L Y O R B . U T I L S . S O C K E T S                 --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2003-2007, Free Software Foundation, Inc.          --
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

with Ada.Exceptions;

with PolyORB.Log;
with PolyORB.Representations.CDR.Common;
with PolyORB.Types;

package body PolyORB.Utils.Sockets is

   use PolyORB.Buffers;
   use PolyORB.Log;
   use PolyORB.Sockets;
   use PolyORB.Representations.CDR.Common;

   package L is new PolyORB.Log.Facility_Log ("polyorb.utils.sockets");
   procedure O (Message : String; Level : Log_Level := Debug)
     renames L.Output;
   function C (Level : Log_Level := Debug) return Boolean
     renames L.Enabled;
   pragma Unreferenced (C); --  For conditional pragma Debug

   --------------------
   -- Connect_Socket --
   --------------------

   procedure Connect_Socket
     (Sock        : PolyORB.Sockets.Socket_Type;
      Remote_Addr : in out PolyORB.Sockets.Sock_Addr_Type) is
   begin
      pragma Debug
        (O ("connect socket" & Image (Sock) & " to " & Image (Remote_Addr)));
      PolyORB.Sockets.Connect_Socket (Sock, Remote_Addr);
   exception
      when E : PolyORB.Sockets.Socket_Error =>
         O ("connect to " & Image (Remote_Addr) & " failed: "
            & Ada.Exceptions.Exception_Message (E), Notice);
         raise;
   end Connect_Socket;

   ---------------------
   -- Marshall_Socket --
   ---------------------

   procedure Marshall_Socket
     (Buffer : access Buffer_Type;
      Sock   : Sock_Addr_Type)
   is
   begin
      --  Marshalling the host name as a string

      Marshall_Latin_1_String (Buffer, Image (Sock.Addr));

      --  Marshalling the port

      Marshall (Buffer, Types.Unsigned_Short (Sock.Port));
   end Marshall_Socket;

   -----------------------
   -- Unmarshall_Socket --
   -----------------------

   procedure Unmarshall_Socket
    (Buffer : access Buffer_Type;
     Sock   :    out Sock_Addr_Type)
   is
      Addr_Image : constant String := Unmarshall_Latin_1_String (Buffer);
      Port : constant Types.Unsigned_Short := Unmarshall (Buffer);
   begin
      Sock.Addr := String_To_Addr (Addr_Image);
      Sock.Port := Port_Type (Port);
   end Unmarshall_Socket;

   --------------------
   -- String_To_Addr --
   --------------------

   function String_To_Addr (Str : Standard.String) return Inet_Addr_Type is
      use PolyORB.Types;

      Hostname_Seen : Boolean := False;
   begin
      for J in Str'Range loop
         if Str (J) not in '0' .. '9'
           and then Str (J) /= '.'
         then
            Hostname_Seen := True;
            exit;
         end if;
      end loop;

      if Hostname_Seen then
         return Addresses (Get_Host_By_Name (Str), 1);
      else
         return Inet_Addr (Str);
      end if;
   end String_To_Addr;

end PolyORB.Utils.Sockets;
