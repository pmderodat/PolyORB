------------------------------------------------------------------------------
--                                                                          --
--                            GLADE COMPONENTS                              --
--                                                                          --
--                 S Y S T E M . G A R L I C . R E M O T E                  --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                            $Revision$                             --
--                                                                          --
--         Copyright (C) 1996,1997 Free Software Foundation, Inc.           --
--                                                                          --
-- GARLIC is free software;  you can redistribute it and/or modify it under --
-- terms of the  GNU General Public License  as published by the Free Soft- --
-- ware Foundation;  either version 2,  or (at your option)  any later ver- --
-- sion.  GARLIC is distributed  in the hope that  it will be  useful,  but --
-- WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHANTABI- --
-- LITY or  FITNESS FOR A PARTICULAR PURPOSE.  See the  GNU General Public  --
-- License  for more details.  You should have received  a copy of the GNU  --
-- General Public License  distributed with GARLIC;  see file COPYING.  If  --
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
--               GLADE  is maintained by ACT Europe.                        --
--               (email: glade-report@act-europe.fr)                        --
--                                                                          --
------------------------------------------------------------------------------

package System.Garlic.Remote is

   --  This package implements calls to the 'rsh' Unix command to
   --  launch other partitions.

   type Launcher_Type is
      access procedure (Host    : in String;         -- Host name
                        Command : in String);        -- Full command line
   --  Launcher function. This function must return when the remote
   --  partition has been launched. It's allowed to raise any exception,
   --  and this will be considered as a failure to launch the remote
   --  partition.
   --  A default launcher using rsh is also provided by the implementation.

   procedure Install_Launcher (Launcher : in Launcher_Type);
   --  Install the launcher

   procedure Launch
     (Host     : in String;
      Command  : in String);
   --  Launch the procedure using either the default or the user provided
   --  launcher.

   procedure Full_Launch
     (Host            : in String;
      Executable_Name : in String;
      Boot_Server  : in String);
   --  Launch the given partition with the correct parameters on the
   --  command line.

   function Get_Host (Partition : String) return String;
   --  Ask a host name for a partition and return it.

   procedure Detach;
   --  Detach a procedure by setsid() and closing the 0, 1 and 2 file
   --  descriptors.

end System.Garlic.Remote;
