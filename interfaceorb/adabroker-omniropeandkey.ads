------------------------------------------------------------------------------
--                                                                          --
--                          ADABROKER COMPONENTS                            --
--                                                                          --
--             A D A B R O K E R . O M N I R O P E A N D K E Y              --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                            $Revision: 1.3 $
--                                                                          --
--         Copyright (C) 1999-2000 ENST Paris University, France.           --
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

--  This package is wrapped around the C++ class Ada_OmniRopeAndKey
--  declared in Ada_OmniRopeAndKey.  It provides the same functions as this
--  package plus the Ada version of thouse where arguments types are to be
--  change.  It includes a Init function since a Ada class has no
--  constructor.

with Ada.Finalization;

with Interfaces.C;
with Interfaces.CPP;

with System;

with AdaBroker; use AdaBroker;
with AdaBroker.Sysdep;
with AdaBroker.Key;
with AdaBroker.Rope;

with CORBA;

package AdaBroker.OmniRopeAndKey is

   type Object is tagged record
      C_Object : System.Address;
      Init_Ok  : Sysdep.Bool;
      Table    : Interfaces.CPP.Vtable_Ptr;
   end record;
   --  C_Object (C)   : pointer on the underlying C omniRopeAndKey object
   --  Init_Ok  (C)   : state of the object (initialized or not)
   --  Table    (Ada) : needed to interface C++ and Ada

   pragma Cpp_Class (Object);
   pragma Cpp_Vtable (Object, Table, 1);
   --  This type is both a C and an Ada class it is wrapped around
   --  Ada_OmniRopeAndKey (see Ada_OmniRopeAndKey.hh)

   type Controlled_Wrapper is
     new Ada.Finalization.Limited_Controlled with record
        Real : Object;
     end record;

   function Get_Rope (Self : in Object'Class) return Rope.Object;
   --  Returns rope attribute of the OmniRopeAndKey object (see
   --  omniInternal.h L248 for more information)

   function Get_Key (Self : in Object'Class) return Key.Object;
   pragma Import (CPP, Get_Key, "key__18Ada_OmniRopeAndKey");
   --  Returns the key attribute of the OmniRopeAndKey object (see
   --  omniInternal.h L250 for more information) wrapper around
   --  Ada_OmniRopeAndKey function key (see Ada_OmniRopeAndKey.hh)

   function Key_Size (Self : in Object'Class) return CORBA.Unsigned_Long;
   --  Returns the size of the key attribute of the OmniRopeAndKey object
   --  (see omniInternal.h L259 for more information)

   function Equals
     (Self  : in Object'Class;
      Other : in Object'Class)
      return Boolean;
   pragma Import (CPP, Equals, "equals__18Ada_OmniRopeAndKeyT0");
   --  Redefinition of the operator to compare the C++ objects (see
   --  Ada_OmniRopeAndKey.hh for more details)


   function "="
     (Self  : in Object'Class;
      Other : in Object'Class) return Boolean
   renames Equals;
   --  Comparaison between 2 OmniRopeAndKey Objects.  uses the C function
   --  Equals.

private

   procedure Init (Self : in out Object'Class);
   pragma Import (CPP, Init, "Init__18Ada_OmniRopeAndKey");
   --  Ada constructor of the class.  This function (or the other function
   --  Init) must be called after each declaration of an Object object. If
   --  it is not, you can not use the object.

   procedure Free (Self : in out Object'Class);
   pragma Import (CPP, Free, "Free__18Ada_OmniRopeAndKey");
   --  Deletes the underlying C++ pointer

   function Constructor return Object'Class;
   pragma Cpp_Constructor (Constructor);
   pragma Import (CPP, Constructor, "__18Ada_OmniRopeAndKey");
   --  Default constructor of the C class.  Actually, this constructor does
   --  nothing and you must call Init to init properly an object.

   procedure Initialize (Self : in out Controlled_Wrapper);
   procedure Finalize (Self : in out Controlled_Wrapper);

end AdaBroker.OmniRopeAndKey;
