------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--            POLYORB.POA_POLICIES.ID_UNIQUENESS_POLICY.UNIQUE              --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--             Copyright (C) 1999-2002 Free Software Fundation              --
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
--              PolyORB is maintained by ENST Paris University.             --
--                                                                          --
------------------------------------------------------------------------------

with PolyORB.Object_Maps;
with PolyORB.POA;
with PolyORB.POA_Policies.Implicit_Activation_Policy;
with PolyORB.POA_Policies.Servant_Retention_Policy.Non_Retain;
with PolyORB.Tasking.Rw_Locks;

package body PolyORB.POA_Policies.Id_Uniqueness_Policy.Unique is

   use PolyORB.Object_Maps;
   use PolyORB.POA_Policies.Implicit_Activation_Policy;
   use PolyORB.Tasking.Rw_Locks;

   ------------
   -- Create --
   ------------

   function Create return Unique_Id_Policy_Access is
   begin
      return new Unique_Id_Policy;
   end Create;

   -------------------------
   -- Check_Compatibility --
   -------------------------

   procedure Check_Compatibility
     (Self           : Unique_Id_Policy;
      Other_Policies : AllPolicies)
   is
      pragma Warnings (Off);
      pragma Unreferenced (Self);
      pragma Warnings (On);

      use PolyORB.POA_Policies.Servant_Retention_Policy.Non_Retain;

      --  See CORBA 3.0, 11.3.8.1 for more details.

      --  Unique_Id and Non_Retain policies are not compatible.
   begin
      for I in Other_Policies'Range loop
         if Other_Policies (I).all in
           POA_Policies.Servant_Retention_Policy.ServantRetentionPolicy
         then
            if Other_Policies (I).all in Non_Retain_Policy then
               raise PolyORB.POA.Invalid_Policy;
               --  XXX we may raise an exception, but should we ?
            end if;
         end if;
      end loop;

   end Check_Compatibility;

   ---------------
   -- Policy_Id --
   ---------------

   function Policy_Id
     (Self : Unique_Id_Policy)
     return String
   is
      pragma Warnings (Off);
      pragma Unreferenced (Self);
      pragma Warnings (On);

   begin
      return "ID_UNIQUENESS_POLICY.UNIQUE_ID";
   end Policy_Id;

   -------------------------------
   -- Ensure_Servant_Uniqueness --
   -------------------------------

   procedure Ensure_Servant_Uniqueness
     (Self      : Unique_Id_Policy;
      OA        : PolyORB.POA_Types.Obj_Adapter_Access;
      P_Servant : Servants.Servant_Access)
   is
      pragma Warnings (Off);
      pragma Unreferenced (Self);
      pragma Warnings (On);

      POA : constant PolyORB.POA.Obj_Adapter_Access
        := PolyORB.POA.Obj_Adapter_Access (OA);

   begin
      if POA.Active_Object_Map /= null then
         Lock_R (POA.Map_Lock);

         if Is_Servant_In (POA.Active_Object_Map.all, P_Servant) then
            Unlock_R (POA.Map_Lock);
            raise PolyORB.POA.Servant_Already_Active;
         end if;

         Unlock_R (POA.Map_Lock);
      end if;
   end Ensure_Servant_Uniqueness;

   --------------------
   -- Activate_Again --
   --------------------

   function Activate_Again
     (Self      : Unique_Id_Policy;
      OA        : PolyORB.POA_Types.Obj_Adapter_Access;
      P_Servant : Servants.Servant_Access;
      Oid       : Object_Id_Access)
     return Object_Id_Access
   is
      pragma Warnings (Off);
      pragma Unreferenced (Self);
      pragma Warnings (On);

      POA : constant PolyORB.POA.Obj_Adapter_Access
        := PolyORB.POA.Obj_Adapter_Access (OA);
   begin
      if Oid /= null then
         --  UNIQUE policy: if already active, return the
         --  previous value.
         return Oid;
      else
         --  If this servant is not activated yet, try to do
         --  implicit activation now.
         return Implicit_Activate_Servant
           (POA.Implicit_Activation_Policy.all, OA, P_Servant);
      end if;
   end Activate_Again;

end PolyORB.POA_Policies.Id_Uniqueness_Policy.Unique;
