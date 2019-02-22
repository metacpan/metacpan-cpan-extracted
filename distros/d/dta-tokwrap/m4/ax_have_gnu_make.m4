##-*- Mode: m4 -*-
##
## File: ax_have_gnu_make.m4
## Author: Bryan Jurish <moocow@cpan.org>
## Description: check if we're running GNU make
##  - subst vars  : @GNU_MAKE_VERSION@
##  - conditionals: HAVE_GNU_MAKE

AC_DEFUN([AX_HAVE_GNU_MAKE],
[
 ##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
 ## ax_have_gnu_make
 ##
 AC_MSG_CHECKING([whether we are using GNU make])
 GNU_MAKE_VERSION=`${MAKE-make} --version -f /dev/null 2>&1 | head -n1 | grep ^GNU`
 if test -n "$GNU_MAKE_VERSION" ; then
   AC_MSG_RESULT(yes)
 else
   AC_MSG_RESULT(no)
 fi
 AM_CONDITIONAL(HAVE_GNU_MAKE,[test -n "$GNU_MAKE_VERSION"])
 AC_SUBST(GNU_MAKE_VERSION)
 ##
 ## /ax_have_gnu_make
 ##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
])
