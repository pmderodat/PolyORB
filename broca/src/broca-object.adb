------------------------------------------------------------------------------
--                                                                          --
--                          ADABROKER COMPONENTS                            --
--                                                                          --
--                         B R O C A . O B J E C T                          --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--          Copyright (C) 1999-2000 ENST Paris University, France.          --
--                                                                          --
-- AdaBroker is free software; you  can  redistribute  it and/or modify it  --
-- under terms of the  GNU General Public License as published by the  Free --
-- Software Foundation;  either version 2,  or (at your option)  any  later --
-- version. AdaBroker  is distributed  in the hope that it will be  useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License  for more details.  You should have received  a copy of the GNU  --
-- General Public License distributed with AdaBroker; see file COPYING. If  --
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
--             AdaBroker is maintained by ENST Paris University.            --
--                     (email: broker@inf.enst.fr)                          --
--                                                                          --
------------------------------------------------------------------------------

with CORBA;
with Broca.IOP;
with Broca.Buffers; use Broca.Buffers;

package body Broca.Object is

   --------------
   -- Marshall --
   --------------

   procedure Marshall
     (Buffer : access Buffer_Type;
      Value  : in Broca.Object.Object_Type) is
   begin
      --  FIXME
      --  Check:
      --  Value of "From" parameter (0);
      --  Potential exception (if Get (Value) cannot be
      --  narrowed to Object_Type)

      Encapsulate_IOR (Buffer, Value);
   end Marshall;

   ----------------
   -- Unmarshall --
   ----------------

   procedure Unmarshall
     (Buffer : access Buffer_Type;
      Result : out Broca.Object.Object_Type)
   is
   begin
      Decapsulate_IOR (Buffer, Result);
   end Unmarshall;

   ------------------
   -- Find_Profile --
   ------------------

   function Find_Profile (Object : Object_Ptr) return IOP.Profile_Ptr is
   begin
      pragma Assert (Object /= null);
      return Object.Profiles (Object.Profiles'First);
   end Find_Profile;

   ---------------------
   -- Encapsulate_IOR --
   ---------------------

   procedure Encapsulate_IOR
     (Buffer : access Buffer_Type;
      --  From   : in Buffer_Index_Type;
      Object : in Object_Type'Class)
   is
   begin
      IOP.Encapsulate_IOR (Buffer, Object.Type_Id, Object.Profiles);
   end Encapsulate_IOR;

   ---------------------
   -- Decapsulate_IOR --
   ---------------------

   procedure Decapsulate_IOR
     (Buffer : access Buffer_Type;
      Object : out Object_Type'Class)
   is
   begin
      IOP.Decapsulate_IOR (Buffer, Object.Type_Id, Object.Profiles);
   end Decapsulate_IOR;

end Broca.Object;
