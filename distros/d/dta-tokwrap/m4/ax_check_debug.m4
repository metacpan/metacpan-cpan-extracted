dnl -*- Mode: autoconf -*-

dnl AX_CHECK_DEBUG
dnl + sets/modifies vars:
dnl   ENABLE_DEBUG
dnl   OFLAGS
dnl   CFLAGS, USER_CFLAGS
dnl + autoheader defines
dnl   ENABLE_DEBUG
dnl + AC_SUBST vars
dnl   OFLAGS
AC_DEFUN([AX_CHECK_DEBUG],
[
##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
## debug ?
##
AC_MSG_CHECKING([whether to build debug version])
AC_ARG_ENABLE(debug,
	AC_HELP_STRING([--enable-debug], [build debug version (default=no)]))

if test "$enable_debug" == "yes" ; then
   AC_MSG_RESULT(yes)

   dnl-- this breaks default shared-library building
   dnl-- on debian/sid:
   dnl    + automake 1.9.6
   dnl    + autoconf 2.59
   dnl    + libtool  1.5.20
   dnl
   dnl AC_DISABLE_SHARED
   ac_OFLAGS="-ggdb -O0"

   AC_DEFINE(DEBUG_ENABLED,1, [Define this to enable debugging code])
   DOXY_DEFINES="$DOXY_DEFINES DEBUG_ENABLED=1"
   CONFIG_OPTIONS="DEBUG=1"
else
  AC_MSG_RESULT(no)
  ac_OFLAGS="-pipe -O2"
  #CONFIG_OPTIONS="$CONFIG_OPTIONS DEBUG=0"
  CONFIG_OPTIONS="DEBUG=0"
fi

case "$USER_CFLAGS" in
  *-O*|*-g*)
    AC_MSG_NOTICE([CFLAGS appears already to contain optimization and/or debug flags - skipping])
    ac_OFLAGS=""
    ;;
  *)
    ;;
esac

case "$USER_CFLAGS" in
  *-W*)
    AC_MSG_NOTICE([CFLAGS appears already to contain warning flags - skipping])
    ac_WFLAGS=""
    ;;
  *)
    ac_WFLAGS="-Wall"
    ;;
esac

if test -n "$ac_OFLAGS" ; then
  if test "$GCC" == "yes" ; then
     AC_MSG_NOTICE([GNU C compiler detected: setting appropriate optimization and/or debugging flags: $ac_WFLAGS $ac_OFLAGS])
     OFLAGS="$ac_OFLAGS $ac_WFLAGS"
  else
     AC_MSG_WARN([GNU C compiler not detected: you must use CFLAGS to set compiler optimization and/or debugging flags])
     OFLAGS=""
   fi
fi  

test -n "$OFLAGS" && USER_CFLAGS="$USER_CFLAGS $OFLAGS" && CFLAGS="$CFLAGS $OFLAGS"
AC_SUBST(OFLAGS)
##
## /debug ?
##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
])
