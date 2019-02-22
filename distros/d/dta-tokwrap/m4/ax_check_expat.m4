dnl -*- Mode: autoconf -*-

dnl AX_CHECK_EXPAT()
dnl + configure args: --disable-expat
dnl + AC_SUBST vars: ENABLE_EXPAT
dnl + modified vars: EXPAT_LIBS, CONFIG_OPTIONS, DOXY_DEFINES

AC_DEFUN([AX_CHECK_EXPAT],
[
dnl vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
dnl check for expat
dnl
dnl expat: user-request
dnl AC_ARG_ENABLE(expat,
dnl 	AC_HELP_STRING([--disable-expat], [Disable expat XML support]),
dnl	[ac_cv_enable_expat="$enableval"],[ac_cv_enable_expat="yes"])

##-- expat: headers
#if test "$ac_cv_enable_expat" != "no" ; then
 for h in expat.h ; do
  AC_CHECK_HEADER($h,
	[have_header="yes"], [have_header="no"], [ ])
  if test "$have_header" = "no" ; then
    AC_MSG_WARN([expat header '$h' not found!])
    AC_MSG_WARN([ + is the directory containing the expat headers in your])
    AC_MSG_WARN([   'CPPFLAGS' environment variable?])
    ac_cv_enable_expat="no"
  fi
 done
#fi ;##-- /ac_cv_enable_expat != no

##-- expat: library: compile
if test "$ac_cv_enable_expat" != "no" ; then

 AC_CHECK_LIB(expat,XML_DefaultCurrent,[ac_cv_have_libexpat="yes"])

 if test "$ac_cv_have_libexpat" != "yes" ; then
    AC_MSG_WARN([expat library not found!])
    AC_MSG_WARN([ + is the directory containing libexpat.a in your])
    AC_MSG_WARN([   'LDFLAGS' environment variable?])
    ac_cv_enable_expat="no"
    EXPAT_LIBS=""
 else
    EXPAT_LIBS="-lexpat"
 fi
fi ;##-- /ac_cv_enable_expat != no
AC_SUBST(EXPAT_LIBS)

##-- expat: config.h flag
if test "$ac_cv_enable_expat" = "no" ; then
  AC_MSG_NOTICE([expat XML support disabled.])
  CONFIG_OPTIONS="$CONFIG_OPTIONS EXPAT=0"
  ENABLE_EXPAT="no"
else
 ##-- ac_cv_enable_expat != no
 AC_DEFINE(EXPAT_ENABLED,1,
	   [Define this to enable expat XML support])
 DOXY_DEFINES="$DOXY_DEFINES EXPAT_ENABLED=1"
 CONFIG_OPTIONS="$CONFIG_OPTIONS EXPAT=1"
 ENABLE_EXPAT="yes"
fi
AC_SUBST(ENABLE_EXPAT)
dnl expat
dnl ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
])
