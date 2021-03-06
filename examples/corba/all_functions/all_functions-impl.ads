------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                   A L L _ F U N C T I O N S . I M P L                    --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--         Copyright (C) 2002-2012, Free Software Foundation, Inc.          --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.                                               --
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

with PortableServer;

package all_functions.Impl is
   --  My own implementation of all_functions object.
   --  This is simply used to define the operations.

   type Object is new PortableServer.Servant_Base with private;

   type Object_Acc is access all Object;

   function Get_the_attribute
     (Self : access Object)
      return CORBA.Short;

   procedure Set_the_attribute
     (Self : access Object;
      To   : CORBA.Short);

   function Get_the_readonly_attribute
     (Self : access Object)
      return CORBA.Short;

   procedure void_proc
     (Self : access Object);

   procedure in_proc
     (Self : access Object;
      a : CORBA.Short;
      b : CORBA.Short;
      c : CORBA.Short);

   procedure out_proc
     (Self : access Object;
      a : out CORBA.Short;
      b : out CORBA.Short;
      c : out CORBA.Short);

   procedure out_in_proc
     (Self : access Object;
      a : out CORBA.Short;
      b : CORBA.Long);

   procedure inout_proc
     (Self : access Object;
      a : in out CORBA.Short;
      b : in out CORBA.Short);

   procedure in_out_proc
     (Self : access Object;
      a : CORBA.Short;
      b : CORBA.Short;
      c : out CORBA.Short;
      d : out CORBA.Short);

   procedure in_inout_proc
     (Self : access Object;
      a : CORBA.Short;
      b : in out CORBA.Short;
      c : CORBA.Short;
      d : in out CORBA.Short);

   procedure out_inout_proc
     (Self : access Object;
      a : out CORBA.Short;
      b : in out CORBA.Short;
      c : in out CORBA.Short;
      d : out CORBA.Short);

   procedure in_out_inout_proc
     (Self : access Object;
      a : CORBA.Short;
      b : out CORBA.Short;
      c : in out CORBA.Short);

   function void_fun
     (Self : access Object)
      return CORBA.Short;

   function in_fun
     (Self : access Object;
      a : CORBA.Short;
      b : CORBA.Short;
      c : CORBA.Short)
      return CORBA.Short;

   procedure out_fun
     (Self : access Object;
      a : out CORBA.Short;
      b : out CORBA.Short;
      c : out CORBA.Short;
      Returns : out CORBA.Short);

   procedure inout_fun
     (Self : access Object;
      a : in out CORBA.Short;
      b : in out CORBA.Short;
      Returns : out CORBA.Short);

   procedure in_out_fun
     (Self : access Object;
      a : CORBA.Short;
      b : CORBA.Short;
      c : out CORBA.Short;
      d : out CORBA.Short;
      Returns : out CORBA.Short);

   procedure in_inout_fun
     (Self : access Object;
      a : CORBA.Short;
      b : in out CORBA.Short;
      c : CORBA.Short;
      d : in out CORBA.Short;
      Returns : out CORBA.Short);

   procedure out_inout_fun
     (Self : access Object;
      a : out CORBA.Short;
      b : in out CORBA.Short;
      c : in out CORBA.Short;
      d : out CORBA.Short;
      Returns : out CORBA.Short);

   procedure in_out_inout_fun
     (Self : access Object;
      a : CORBA.Short;
      b : out CORBA.Short;
      c : in out CORBA.Short;
      Returns : out CORBA.Short);

   procedure oneway_void_proc
     (Self : access Object);

   procedure oneway_in_proc
     (Self : access Object;
      a : CORBA.Short;
      b : CORBA.Short);

   function oneway_checker (Self : access Object) return CORBA.Short;

   procedure StopServer (Self : access Object);

private

   type Object is new PortableServer.Servant_Base with record
      Attribute : CORBA.Short;
   end record;

end all_functions.Impl;
