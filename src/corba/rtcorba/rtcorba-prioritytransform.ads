------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--            R T C O R B A . P R I O R I T Y T R A N S F O R M             --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--         Copyright (C) 2003-2004 Free Software Foundation, Inc.           --
--                                                                          --
-- This specification is derived from the CORBA Specification, and adapted  --
-- for use with PolyORB. The copyright notice above, and the license        --
-- provisions that follow apply solely to the contents neither explicitely  --
-- nor implicitely specified by the CORBA Specification defined by the OMG. --
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

with PortableServer;

package RTCORBA.PriorityTransform is

   type Object is tagged private;

   --  Implementation Note: RT-CORBA specifications (formal/03-11-01)
   --  is unclear and does not state default behavior for this
   --  object. By default, these functions will always set Returns
   --  parameter to False.
   --
   --  Other implementations will provide a functionnal mapping.

   procedure Inbound
     (Self         : in     Object;
      The_Priority : in out RTCORBA.Priority;
      Oid          : in     PortableServer.ObjectId;
      Returns      :    out CORBA.Boolean);

   procedure Outbound
     (Self         : in     Object;
      The_Priority : in out RTCORBA.Priority;
      Oid          : in     PortableServer.ObjectId;
      Returns      :    out CORBA.Boolean);

private

   type Object is tagged null record;

end RTCORBA.PriorityTransform;