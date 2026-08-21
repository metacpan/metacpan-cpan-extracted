#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.66])
AC_INIT(x11guirecord, 0.29, ctrondlp@cpan.org)
AM_INIT_AUTOMAKE(x11guirecord, 0.29)
AC_CONFIG_SRCDIR([src/script_file.c])
AC_CONFIG_HEADERS([config.h])

# Checks for programs.
AC_PROG_CC

# --- Compiler Flag Portability Guard ---
# -Wstrict-prototypes/-Wmissing-prototypes/-Wmissing-declarations are
# GCC/Clang-specific flag spellings that Sun Studio cc (Solaris), xlc
# (AIX), and aCC (HP-UX) don't recognize; combined with -Werror that would
# turn "unrecognized option" into a hard configure/build failure on those
# compilers. Only add them when the detected compiler is GCC-compatible
# ($GCC is set to "yes" by AC_PROG_CC in that case).
if test "x$GCC" = "xyes"; then
  WARN_CFLAGS="-Wall -Werror -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations"
else
  WARN_CFLAGS=""
fi
AC_SUBST([WARN_CFLAGS])

# Checks for libraries.

# X11: AC_PATH_XTRA (a superset of AC_PATH_X) locates the X headers/libs,
# and any platform-specific extra libraries needed alongside them (e.g.
# -lsocket -lnsl on some Solaris configurations), substituting X_CFLAGS,
# X_LIBS, X_PRE_LIBS, and X_EXTRA_LIBS for use in src/Makefile.am -- this
# is far more reliable across platforms than a hardcoded path list.
AC_PATH_XTRA

# popt is required for command-line parsing and isn't part of the base OS
# on any of our target platforms (Linux, FreeBSD, Solaris, HP-UX, AIX), so
# probe for it and fail with a clear message at configure time rather than
# an opaque compile/link error part-way through the build.
AC_CHECK_HEADER([popt.h], [],
  [AC_MSG_ERROR([popt.h not found. Install the 'popt' development package and try again.])])
AC_CHECK_LIB([popt], [poptGetContext], [],
  [AC_MSG_ERROR([libpopt not found. Install the 'popt' library and try again.])])

# GNU gettext (bindtextdomain/textdomain/gettext via libintl.h) is native
# on Linux, the BSDs, and modern Solaris, but NOT on AIX or HP-UX, which
# use catgets-based i18n instead. No .po/.mo catalogs are shipped in this
# project, so translation support has no functional payload today --
# treat it as optional and degrade gracefully (see Common.h) instead of
# hard-requiring it.
AC_CHECK_HEADER([libintl.h], [have_libintl_h=yes], [have_libintl_h=no])
if test "x$have_libintl_h" = "xyes"; then
  AC_SEARCH_LIBS([gettext], [intl], [have_gettext=yes], [have_gettext=no])
else
  have_gettext=no
fi
if test "x$have_gettext" = "xyes"; then
  AC_DEFINE([HAVE_GETTEXT], [1],
    [Define if a usable GNU gettext (libintl.h + bindtextdomain/textdomain/gettext) was found])
else
  AC_MSG_WARN([GNU gettext not found or unusable; building without translation support (no .po/.mo catalogs are shipped, so this has no effect on functionality).])
fi

# Checks for header files.
AC_CHECK_HEADERS([stdlib.h string.h strings.h locale.h sys/time.h unistd.h])

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.
AC_CHECK_FUNCS([gettimeofday])

AC_OUTPUT(Makefile src/Makefile man/Makefile)
