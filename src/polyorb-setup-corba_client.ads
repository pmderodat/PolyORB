--  Set up a test ORB.

--  $Id$

with PolyORB.ORB;

package PolyORB.Setup.CORBA_Client is

   pragma Elaborate_Body;

   type Parameterless_Procedure is access procedure;

   procedure Initialize_CORBA_Client
     (SL_Init : Parameterless_Procedure;
      TP : ORB.Tasking_Policy_Access);
   --  Initialize middleware subsystems and create ORB.
   --  SL_Init must initialize one of the Soft_Links implementations.
   --  TP must be the chosen ORB tasking policy.

end PolyORB.Setup.CORBA_Client;
