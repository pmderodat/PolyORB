with vehicle.Skeleton ;
with tank.Impl ;
with tank.Marshal ;
with Netbufferedstream ;
with Membufferedstream ;
with Omniropeandkey ;
with Giop ;
with Corba ;
with weapon ;
with classes_IDL_FILE.marshal ;
use vehicle.Skeleton ;
use tank.Impl ;
use tank.Marshal ;
use Netbufferedstream ;
use Membufferedstream ;
use Omniropeandkey ;
use Giop ;
use Corba ;
use weapon ;
use classes_IDL_FILE.marshal ;
use Netbufferedstream ;
use Membufferedstream ;
use type Corba.Unsigned_Long ;

package body tank.Skeleton is

   procedure Dispatch (Myself : in Omniobject.Implemented_Object_Ptr ;
                       Orls : in out Giop_S.Object ;
                       Orl_Op : in Standard.String ;
                       Orl_Response_Expected : in Corba.Boolean ;
                       Dispatch_Returns : out Corba.Boolean) is
      Self : tank.Impl.Object_Ptr := tank.Impl.Object_Ptr(Myself) ;
   begin
   -----------------------
   -- IDL definitions   --
   -----------------------

      if Orl_Op = "move" then
         declare
            fast : Corba.String ;
            Returns : Corba.String ;
            Mesg_Size : Corba.Unsigned_Long ;
         begin
            -- unmarshalls arguments
            UnMarshall(fast, Orls) ;
            -- change state
            Giop_S.Request_Received(Orls) ;
            -- call the implementation
            Returns := tank.Impl.move(Self, fast) ;
            -- compute the size of the replied message
            Mesg_Size := Giop_S.Reply_Header_Size ;
            Mesg_Size := Align_Size (Returns, Mesg_Size) ;
            -- Initialisation of the reply
            Giop_S.Initialize_Reply (Orls, Giop.NO_EXCEPTION, Mesg_Size) ;
            -- Marshall the arguments
            Marshall (Returns, Orls) ;
            -- inform the orb
            Giop_S.Reply_Completed (Orls) ;
            Dispatch_Returns := True ;
            return ;
         end ;
      end if ;



   -----------------------------
   -- inheritance from weapon
   -----------------------------

      if Orl_Op = "shoot" then
         declare
            ranges : Corba.Long ;
            Mesg_Size : Corba.Unsigned_Long ;
         begin
            -- unmarshalls arguments
            UnMarshall(ranges, Orls) ;
            -- change state
            Giop_S.Request_Received(Orls) ;
            -- call the implementation
            tank.Impl.shoot(Self, ranges) ;
            -- compute the size of the replied message
            Mesg_Size := Giop_S.Reply_Header_Size ;
            -- Initialisation of the reply
            Giop_S.Initialize_Reply (Orls, Giop.NO_EXCEPTION, Mesg_Size) ;
            -- Marshall the arguments
            -- inform the orb
            Giop_S.Reply_Completed (Orls) ;
            Dispatch_Returns := True ;
            return ;
         end ;
      end if ;



      vehicle.Skeleton.Dispatch(Myself,
                             Orls,
                             Orl_Op,
                             Orl_Response_Expected,
                             Dispatch_Returns);
   end ;

end tank.Skeleton  ;
