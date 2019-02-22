dnl -*- Mode: autoconf -*-
AC_DEFUN([AX_CHECK_PERL],
[
##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
## perl
AC_ARG_VAR(PERL, [Path to your perl interpreter, "no" to disable])
AC_MSG_CHECKING([for PERL environment variable])
if test -n "$PERL" ; then
  AC_MSG_RESULT([$PERL])
else
  AC_MSG_RESULT(no)
  AC_PATH_PROG(PERL,[perl],[no])
fi
if test -z "$PERL" -o "$PERL" = "no"; then
  AC_MSG_WARN([perl missing or disabled])
  AC_MSG_WARN([- generation of alternate documentation formats disabled.])
  PERL=no
fi
AC_SUBST(PERL)
## /perl
##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
])
