dnl aclocal.m4 generated automatically by aclocal 1.4-p6

dnl Copyright (C) 1994, 1995-8, 1999, 2001 Free Software Foundation, Inc.
dnl This file is free software; the Free Software Foundation
dnl gives unlimited permission to copy and/or distribute it,
dnl with or without modifications, as long as this notice is preserved.

dnl This program is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY, to the extent permitted by law; without
dnl even the implied warranty of MERCHANTABILITY or FITNESS FOR A
dnl PARTICULAR PURPOSE.

# Do all the work for Automake.  This macro actually does too much --
# some checks are only needed if your package does certain things.
# But this isn't really a big deal.

# serial 1

dnl Usage:
dnl AM_INIT_AUTOMAKE(package,version, [no-define])

AC_DEFUN([AM_INIT_AUTOMAKE],
[AC_REQUIRE([AM_SET_CURRENT_AUTOMAKE_VERSION])dnl
AC_REQUIRE([AC_PROG_INSTALL])
PACKAGE=[$1]
AC_SUBST(PACKAGE)
VERSION=[$2]
AC_SUBST(VERSION)
dnl test to see if srcdir already configured
if test "`cd $srcdir && pwd`" != "`pwd`" && test -f $srcdir/config.status; then
  AC_MSG_ERROR([source directory already configured; run "make distclean" there first])
fi
ifelse([$3],,
AC_DEFINE_UNQUOTED(PACKAGE, "$PACKAGE", [Name of package])
AC_DEFINE_UNQUOTED(VERSION, "$VERSION", [Version number of package]))
AC_REQUIRE([AM_SANITY_CHECK])
AC_REQUIRE([AC_ARG_PROGRAM])
dnl FIXME This is truly gross.
missing_dir=`cd $ac_aux_dir && pwd`
AM_MISSING_PROG(ACLOCAL, aclocal-${am__api_version}, $missing_dir)
AM_MISSING_PROG(AUTOCONF, autoconf, $missing_dir)
AM_MISSING_PROG(AUTOMAKE, automake-${am__api_version}, $missing_dir)
AM_MISSING_PROG(AUTOHEADER, autoheader, $missing_dir)
AM_MISSING_PROG(MAKEINFO, makeinfo, $missing_dir)
AC_REQUIRE([AC_PROG_MAKE_SET])])

# Copyright 2002  Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA

# AM_AUTOMAKE_VERSION(VERSION)
# ----------------------------
# Automake X.Y traces this macro to ensure aclocal.m4 has been
# generated from the m4 files accompanying Automake X.Y.
AC_DEFUN([AM_AUTOMAKE_VERSION],[am__api_version="1.4"])

# AM_SET_CURRENT_AUTOMAKE_VERSION
# -------------------------------
# Call AM_AUTOMAKE_VERSION so it can be traced.
# This function is AC_REQUIREd by AC_INIT_AUTOMAKE.
AC_DEFUN([AM_SET_CURRENT_AUTOMAKE_VERSION],
	 [AM_AUTOMAKE_VERSION([1.4-p6])])

#
# Check to make sure that the build environment is sane.
#

AC_DEFUN([AM_SANITY_CHECK],
[AC_MSG_CHECKING([whether build environment is sane])
# Just in case
sleep 1
echo timestamp > conftestfile
# Do `set' in a subshell so we don't clobber the current shell's
# arguments.  Must try -L first in case configure is actually a
# symlink; some systems play weird games with the mod time of symlinks
# (eg FreeBSD returns the mod time of the symlink's containing
# directory).
if (
   set X `ls -Lt $srcdir/configure conftestfile 2> /dev/null`
   if test "[$]*" = "X"; then
      # -L didn't work.
      set X `ls -t $srcdir/configure conftestfile`
   fi
   if test "[$]*" != "X $srcdir/configure conftestfile" \
      && test "[$]*" != "X conftestfile $srcdir/configure"; then

      # If neither matched, then we have a broken ls.  This can happen
      # if, for instance, CONFIG_SHELL is bash and it inherits a
      # broken ls alias from the environment.  This has actually
      # happened.  Such a system could not be considered "sane".
      AC_MSG_ERROR([ls -t appears to fail.  Make sure there is not a broken
alias in your environment])
   fi

   test "[$]2" = conftestfile
   )
then
   # Ok.
   :
else
   AC_MSG_ERROR([newly created file is older than distributed files!
Check your system clock])
fi
rm -f conftest*
AC_MSG_RESULT(yes)])

dnl AM_MISSING_PROG(NAME, PROGRAM, DIRECTORY)
dnl The program must properly implement --version.
AC_DEFUN([AM_MISSING_PROG],
[AC_MSG_CHECKING(for working $2)
# Run test in a subshell; some versions of sh will print an error if
# an executable is not found, even if stderr is redirected.
# Redirect stdin to placate older versions of autoconf.  Sigh.
if ($2 --version) < /dev/null > /dev/null 2>&1; then
   $1=$2
   AC_MSG_RESULT(found)
else
   $1="$3/missing $2"
   AC_MSG_RESULT(missing)
fi
AC_SUBST($1)])


dnl Usage: AM_PROG_GNAT
dnl Look for an Ada compiler (gnatmake)

AC_DEFUN([AM_PROG_GNAT],
[AC_BEFORE([$0], [AM_TRY_GNAT])
AC_CHECK_PROGS(GNAT, gnatmake)
])

dnl Usage: AM_TRY_GNAT(filename, content, success, failure)
dnl Compile an Ada program and report its success or failure

AC_DEFUN([AM_TRY_GNAT],
[AC_REQUIRE([AM_PROG_GNAT])
mkdir conftest
cat > conftest/[$1] <<EOF
[$2]
EOF
ac_try="cd conftest && $GNAT -c $1 > /dev/null 2>../conftest.out"
if AC_TRY_EVAL(ac_try); then
  ifelse([$3], , :, [rm -rf conftest*
  $3])
else
  ifelse([$4], , :, [ rm -rf conftest*
  $4])
fi
rm -f conftest*])

dnl Usage: AM_PROG_GNAT_FOR_HOST
dnl Try to compile a simple Ada program to test the compiler installation
dnl (especially the standard libraries such as Ada.Text_IO)

AC_DEFUN([AM_PROG_GNAT_FOR_HOST],
[AC_REQUIRE([AM_PROG_GNAT])
AC_MSG_CHECKING([if the Ada compiler works])
AM_TRY_GNAT([check.adb],
[with Ada.Text_IO;
procedure Check is
begin
   null;
end Check;
], [
 AC_MSG_RESULT(yes)
 GNAT_FOR_HOST=gnatmake
],
[
  AC_MSG_RESULT(no)
AC_MSG_ERROR([Ada compiler is not working])])])

dnl Usage: AM_GNAT_PREREQ(date, version)
dnl Check that GNAT is at least as recent as date (YYMMDD)

AC_DEFUN([AM_GNAT_PREREQ],
[AC_REQUIRE([AM_PROG_GNAT_FOR_HOST])
AC_CHECK_PROG(GNATLS, gnatls, gnatls)
AC_CHECK_PROG(SED, sed, sed)
AC_MSG_CHECKING([if the Ada compiler is recent enough])
am_gnatls_date=`$GNATLS -v | $SED -ne 's/^GNATLS .*(\(.*\)).*$/\1/p'`
if test "$1" -le "$am_gnatls_date"; then
  AC_MSG_RESULT(yes)
else
  AC_MSG_RESULT(no)
  am_gnatls_version=`$GNATLS -v | $SED -ne 's/^GNATLS \(.*\) (.*.*$/\1/p'`
  AC_MSG_ERROR([Please get a version of GNAT no older than [$2 ($1)]
(it looks like you only have GNAT [$am_gnatls_version ($am_gnatls_date)])])
fi])

dnl Usage: AM_PROG_GNAT_FOR_TARGET
dnl Look for an Ada compiler for the target (same as the host one if host and
dnl target are equal)

AC_DEFUN([AM_PROG_GNAT_FOR_TARGET],
[AC_REQUIRE([AM_PROG_GNAT_FOR_HOST])
 if test $host = $target; then
   GNAT_FOR_TARGET=$GNAT_FOR_HOST
   AC_SUBST(GNAT_FOR_TARGET)
 else
   AC_CHECK_PROGS(GNAT_FOR_TARGET,
     [$target_alias-$GNAT_FOR_HOST $target-$GNAT_FOR_HOST])
 fi
])

dnl Usage: AM_SUPPORT_RPC_ABORTION
dnl For GNAT5 with ZCX, we cannot support RPC abortion. In this case,
dnl RPC execution may fail even when not aborted. Remove this feature
dnl except when user really wants it to be enabled. When we can provide
dnl this feature with SJLJ exception model and when the user really wants
dnl it, then build GLADE with SJLJ model being the default.

AC_DEFUN([AM_SUPPORT_RPC_ABORTION],
[AC_REQUIRE([AM_PROG_GNAT_FOR_HOST])
AC_CHECK_PROG(GNATLS, gnatls, gnatls)
GNAT_RTS_FLAG="";
am_gnat_major_version=`$GNATLS -v | $SED -ne 's/^GNATLS [[^0-9]]*\(.\).*$/\1/p'`
am_system_ads=`$GNATLS -a -s system.ads`
am_gnatlib_dir=`dirname $am_system_ads`
am_gnatlib_dir=`dirname $am_gnatlib_dir`
am_gnat_zcx_by_default=`$SED -ne 's/ZCX_By_Default.*:= *\(.*\);$/\1/p' \
  $am_system_ads`
if test $am_gnat_major_version = "5"; then
  if test $am_gnat_zcx_by_default = "True"; then
    if test $SUPPORT_RPC_ABORTION = "True"; then
      if test -f $am_gnatlib_dir/rts-sjlj/adainclude/system.ads; then
        GNAT_RTS_FLAG="--RTS=rts-sjlj"
        am_gnat_zcx_by_default="False"
      fi
    else
      SUPPORT_RPC_ABORTION="False"
    fi
  else
    SUPPORT_RPC_ABORTION="True"
  fi
else
  SUPPORT_RPC_ABORTION="True"
fi
if test $am_gnat_zcx_by_default = "True"; then
  EXCEPTION_MODEL="zcx"
else
  EXCEPTION_MODEL="sjlj"
fi
])


