------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                            C X E 4 0 0 2 _ A                             --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--           Copyright (C) 2012, Free Software Foundation, Inc.             --
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

pragma Warnings (Off);
pragma Style_Checks (Off);
-----------------------------------------------------------------------------

with CXE4002_Common;
with CXE4002_Part_A1;
with CXE4002_Part_A2;
with Report;
procedure CXE4002_A is
begin
  -- this partition is a server that deals with calls 
  -- from CXE4002_B.  
  Report.Test ("CXE4002_A", "Parameter passing across partitions (server)");
  CXE4002_Part_A1.Can_Quit; -- OK to quit now.

  -- Report.Result is called in the body of CXE4002_Part_A1.
end CXE4002_A;
