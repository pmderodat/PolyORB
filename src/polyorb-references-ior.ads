------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--               P O L Y O R B . R E F E R E N C E S . I O R                --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--         Copyright (C) 2002-2003 Free Software Foundation, Inc.           --
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

--  Representation of object references as typed
--  Interoperable Object References.

--  An IOR aggregates the identification of an interface (i.e. a type
--  identifier) and a set of profiles designating an object that supports
--  this interface. An IOR can be converted to a stringified
--  representation by marshalling it according to CDR, and converting
--  the resulting stream element array into a string of hexadecimal digits.

--  $Id$

with Ada.Streams;

with PolyORB.Buffers;
with PolyORB.Binding_Data;

package PolyORB.References.IOR is

   use PolyORB.Buffers;

   procedure Marshall_Profile
     (Buffer  : access Buffer_Type;
      P       :        Binding_Data.Profile_Access;
      Success :    out Boolean);

   function Unmarshall_Profile
     (Buffer : access Buffer_Type)
     return Binding_Data.Profile_Access;
   --  Return null if failed

   procedure Marshall_IOR
     (Buffer : access Buffer_Type;
      Value  : in     PolyORB.References.Ref);

   function  Unmarshall_IOR
     (Buffer : access Buffer_Type)
     return  PolyORB.References.Ref;

   --------------------------------------
   -- Object reference <-> opaque data --
   --------------------------------------

   function Object_To_Opaque (IOR : PolyORB.References.Ref)
     return Ada.Streams.Stream_Element_Array;

   function Opaque_To_Object
     (Opaque : access Ada.Streams.Stream_Element_Array)
     return PolyORB.References.Ref;

   ------------------------------------------
   -- Object reference <-> stringified IOR --
   ------------------------------------------

   function Object_To_String (IOR : PolyORB.References.Ref) return String;

   ---------------------
   -- Profile Factory --
   ---------------------

   type Marshall_Profile_Body_Type is access procedure
     (Buffer  : access Buffers.Buffer_Type;
      Profile :        Binding_Data.Profile_Access);

   type Unmarshall_Profile_Body_Type is access function
     (Buffer  : access Buffers.Buffer_Type)
     return Binding_Data.Profile_Access;

   procedure Register
     (Profile                 : in Binding_Data.Profile_Tag;
      Marshall_Profile_Body   : in Marshall_Profile_Body_Type;
      Unmarshall_Profile_Body : in Unmarshall_Profile_Body_Type);

private

   function String_To_Object (Str : String) return PolyORB.References.Ref;

end PolyORB.References.IOR;