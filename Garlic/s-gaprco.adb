------------------------------------------------------------------------------
--                                                                          --
--                           GARLIC COMPONENTS                              --
--                                                                          --
--      S Y S T E M . G A R L I C . P R O T O C O L S . C O N F I G         --
--                                                                          --
--                                B o d y                                   --
--                                                                          --
--                           $Revision$                              --
--                                                                          --
--           Copyright (C) 1996 Free Software Foundation, Inc.              --
--                                                                          --
-- GARLIC is free software;  you can redistribute it and/or modify it under --
-- terms of the  GNU General Public License  as published by the Free Soft- --
-- ware Foundation;  either version 2,  or (at your option)  any later ver- --
-- sion.  GARLIC is distributed  in the hope that  it will be  useful,  but --
-- WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHANTABI- --
-- LITY or  FITNESS FOR A PARTICULAR PURPOSE.  See the  GNU General Public  --
-- License  for more details.  You should have received  a copy of the GNU  --
-- General Public License  distributed with GARLIC;  see file COPYING.  If  --
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
--               GARLIC is maintained by ACT Europe.                        --
--            (email:distribution@act-europe.gnat.com).                     --
--                                                                          --
------------------------------------------------------------------------------

with System.Garlic.Loopback;
pragma Elaborate_All (System.Garlic.Loopback);

with System.Garlic.TCP;
pragma Elaborate_All (System.Garlic.TCP);

package body System.Garlic.Protocols.Config is

   --  This package should be created during GARLIC installation.
   --  It should register all the protocols present in the distribution

   procedure Register (P : in Protocol_Access);
   --  Register the protocol as a present protocol.

   --------------
   -- Register --
   --------------

   procedure Register (P : in Protocol_Access) is
   begin
      for I in Protocol_Table'Range loop
         if Protocol_Table (I) = null then
            Protocol_Table (I) := P;
            return;
         end if;
      end loop;
      raise Constraint_Error;
   end Register;

   ------------
   -- Create --
   ------------

   procedure Create is
   begin
      Register (System.Garlic.Loopback.Create);
      Register (System.Garlic.TCP.Create);
   end Create;

end System.Garlic.Protocols.Config;
