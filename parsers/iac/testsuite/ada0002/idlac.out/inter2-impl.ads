-------------------------------------------------
--  This file has been generated automatically
--  by IDLAC (http://libre.act-europe.fr/polyorb/)
-------------------------------------------------
pragma Style_Checks (Off);

with CORBA;
with PortableServer;

package Inter2.Impl is

   type Object is
     new PortableServer.Servant_Base with private;

   type Object_Ptr is access all Object'Class;

   function get_attr1
     (Self : access Object)
     return Inter2.New_Float;

   procedure set_attr1
     (Self : access Object;
      To : in Inter2.New_Float);

   function ConvertNew
     (Self : access Object;
      N : in CORBA.Float)
     return Inter2.New_Float;

private

   type Object is
     new PortableServer.Servant_Base with record
      --  Insert components to hold the state
      --  of the implementation object.
      null;
   end record;

end Inter2.Impl;