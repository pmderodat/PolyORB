------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--           T E S T _ S E R V A N T A C T I V A T O R . I M P L            --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2005-2012, Free Software Foundation, Inc.          --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.                                               --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
--                  PolyORB is maintained by AdaCore                        --
--                     (email: sales@adacore.com)                           --
--                                                                          --
------------------------------------------------------------------------------

with CORBA.Object;

with PortableServer.Helper;
with PortableServer.ServantManager;

with Test_Globals;

package body Test_ServantActivator.Impl is

   ---------------
   -- Incarnate --
   ---------------

   function Incarnate
     (Self    : access Object;
      Oid     :        PortableServer.ObjectId;
      Adapter :        PortableServer.POA_Forward.Ref)
      return PortableServer.Servant
   is
      pragma Unreferenced (Self, Oid, Adapter);

   begin
      PortableServer.Helper.Raise_ForwardRequest
        (PortableServer.ForwardRequest_Members'
         (Forward_Reference => CORBA.Object.Ref (Test_Globals.Object_1)));

      return null;
   end Incarnate;

   ----------
   -- Is_A --
   ----------

   function Is_A
     (Self            : not null access Object;
      Logical_Type_Id : Standard.String) return Boolean
   is
      pragma Unreferenced (Self);
   begin
      return
        CORBA.Is_Equivalent
          (Logical_Type_Id, Test_ServantActivator.Repository_Id)
          or else
        CORBA.Is_Equivalent
          (Logical_Type_Id, PortableServer.ServantActivator.Repository_Id)
          or else
        CORBA.Is_Equivalent
          (Logical_Type_Id, PortableServer.ServantManager.Repository_Id)
          or else
        CORBA.Is_Equivalent
          (Logical_Type_Id, "IDL:omg.org/CORBA/Object:1.0");
   end Is_A;

end Test_ServantActivator.Impl;
