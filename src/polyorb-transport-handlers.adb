------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--           P O L Y O R B . T R A N S P O R T . H A N D L E R S            --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2003-2004 Free Software Foundation, Inc.           --
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

--  Event handlers associated with all transport access points and
--  transport endpoints.

--  $Id$

with PolyORB.Asynch_Ev;
with PolyORB.Components;
with PolyORB.Filters.Interface;
with PolyORB.ORB;

package body PolyORB.Transport.Handlers is

   ------------------
   -- Handle_Event --
   ------------------

   procedure Handle_Event
     (H : access TE_AES_Event_Handler)
   is
      use PolyORB.Components;
      use PolyORB.ORB;

      Reply : constant Message'Class
        := Emit
        (Component_Access (H.TE),
         Filters.Interface.Data_Indication'
         (Data_Amount => 0));
      --  The size of the data received is not known yet.

   begin

      if Reply in Filters.Interface.Filter_Error then

         --  Notify the tasking policy that an endpoint is being destroyed.

         Handle_Close_Connection
           (H.ORB.Tasking_Policy, H.TE);

         --  Close the endpoint.

         Emit_No_Reply
           (Component_Access (H.TE),
            Filters.Interface.Disconnect_Indication'(null record));

         declare
            Dependent_Binding_Object : constant PolyORB.Smart_Pointers.Ref
              := H.TE.Dependent_Binding_Object;
            pragma Unreferenced (Dependent_Binding_Object);
         begin

            --  Detach the TE from its dependent binding object. This
            --  must be done while ensuring that the reference counter
            --  on the BO is still non-zero, otherwise this could
            --  cause the TE to be destroyed before it is completely
            --  detached.

            Smart_Pointers.Set (H.TE.Dependent_Binding_Object, null);

            --  The complete binding object will be finalised when
            --  this block is exited if it is not referenced anymore.

         end;

      else
         null;
      end if;

   end Handle_Event;

end PolyORB.Transport.Handlers;