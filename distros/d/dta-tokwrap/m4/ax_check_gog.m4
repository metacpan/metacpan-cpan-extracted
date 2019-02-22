dnl -*- Mode: autoconf -*-

AC_DEFUN([AX_CHECK_GOG],
[
##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
## optgen.perl & Getopt::Gen
##
AC_ARG_VAR(OPTGEN_PERL, [Path to the 'optgen.perl' script; "no" to disable])

##-- test for working optgen.perl
AC_MSG_CHECKING([whether Getopt::Gen works])
  if test "$PERL" != "no" && $PERL -MGetopt::Gen -e'exit 0;' >>config.log 2>&1; then
  AC_MSG_RESULT(yes)
else
  AC_MSG_RESULT(no)
  AC_MSG_WARN([Getopt::Gen (or something it depends on) is broken!])
  AC_MSG_WARN([- you probably need to fix your Parse::Lex module])
  OPTGEN_PERL="no"
fi

if test -z "$OPTGEN_PERL" ; then
  AC_PATH_PROG(OPTGEN_PERL,[optgen.perl],[no])
fi

AC_MSG_NOTICE([setting OPTGEN_PERL=$OPTGEN_PERL])
AC_SUBST(OPTGEN_PERL)

if test "$OPTGEN_PERL" = "no" ; then
  AC_MSG_WARN([optgen.perl script is missing, broken, or disabled.])
  AC_MSG_WARN([- regeneration of command-line parsers from .gog specifications disabled.])
  AC_MSG_WARN([- regeneration of POD documentation from .gog specifications disabled.])
fi
AM_CONDITIONAL(HAVE_OPTGEN, [test "$OPTGEN_PERL" != "no"])

##-- check for strdup (needed for gog-generated files)
AC_CHECK_FUNC(strdup,[AC_DEFINE(HAVE_STRDUP,1,[Define this if you have the strdup() function])])
##
## /optgen.perl
##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
])
