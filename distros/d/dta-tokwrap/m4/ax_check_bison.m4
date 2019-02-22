dnl -*- Mode: autoconf -*-

AC_DEFUN([AX_CHECK_BISON],
[
##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
## bison
##
AC_ARG_VAR(BISON, [Path to GNU bison; "no" to disable])
if test -z "$BISON" ; then
  AC_PATH_PROG(BISON,bison,[no])
fi

AC_MSG_NOTICE([setting BISON=$BISON])

if test "$BISON" = "no"; then
  AC_MSG_WARN([GNU bison is missing, broken, or disabled])
  AC_MSG_WARN([- compilation from .y parser source files disabled])
fi

AM_CONDITIONAL(HAVE_BISON,[test "$BISON" != "no"])
##
## /bison
##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
])
