dnl #
dnl #  aclocal.m4 -- Local M4 functions for GNU autoconf
dnl #  Copyright (c) Ralf S. Engelschall, <rse@engelschall.com>
dnl #
dnl #  NOTICE:
dnl #      all defined macros are named AC_*
dnl #      all defined and used variables are named acl-*
dnl #
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  support for User Variables 
dnl ##
dnl ##########################################################
dnl
define(AC_UVAR_CODE,[dnl
if test .[$]ac_with_uvar = .yes; then
$1
fi
])
dnl
define(AC_UVAR_ANTICODE,[dnl
if test .[$]ac_with_uvar = .no; then
$1
fi
])
dnl
dnl
dnl -----------
dnl
dnl
define(AC_UVAR_INIT,[dnl
AC_ARG_WITH(uvar,dnl
[  --with-uvar             support for Runtime User Variable Setup],
ac_with_uvar=yes,
ac_with_uvar=no
)dnl
dnl
dnl # because since autoconf 2.3 the following two lines
dnl # are at AC_OUTPUT which is to late for us :-(
test "x$prefix"      = xNONE && prefix=$ac_default_prefix
test "x$exec_prefix" = xNONE && exec_prefix="${prefix}"
dnl
AC_UVAR_CODE(dnl
ac_uvar_editfile=/tmp/usrvar.tmp
rm -f $ac_uvar_editfile
echo "##" >>$ac_uvar_editfile
echo "##  RunTime User Variable Setup" >>$ac_uvar_editfile
echo -n "##  GNU autoconf Version " >>$ac_uvar_editfile
echo "AC_ACVERSION" >>$ac_uvar_editfile
echo "##  created: `date`" >>$ac_uvar_editfile
echo "##" >>$ac_uvar_editfile
echo "" >>$ac_uvar_editfile
)dnl
])dnl
dnl
dnl
dnl -----------
dnl 
define(AC_UVAR_VERB,[dnl
AC_UVAR_CODE(dnl
cat >>$ac_uvar_editfile <<'EOF'
$1dnl
EOF
)dnl
])dnl
dnl
dnl -----------
dnl 
define(AC_SET,[dnl
$1="$2"
AC_SUBST($1) dnl
])dnl
dnl
dnl -----------
dnl 
define(AC_UVAR_SET,[dnl
AC_SET($1, $2) dnl
AC_UVAR_CODE(dnl
    echo '$1="$2"' >>$ac_uvar_editfile
)dnl
])dnl
dnl 
dnl -----------
dnl 
define(AC_UVAR_SETQUOTE,[dnl
AC_SET($1, $2) dnl
AC_UVAR_CODE(dnl
    echo -n '$1="' >>$ac_uvar_editfile
    echo -n "$2" >>$ac_uvar_editfile
    echo '"' >>$ac_uvar_editfile
)dnl
])dnl
dnl 
dnl -----------
dnl 
define(AC_UVAR_SETCHK,[dnl
if test -z "[$]$1"; then
AC_UVAR_SET($1, $2) dnl
else
if test .[$]$1 = .NONE; then
AC_UVAR_SET($1, $2) dnl
else
AC_SUBST($1)dnl
AC_UVAR_CODE(dnl
    echo -n '$1="' >>$ac_uvar_editfile
    echo -n "[$]$1" >>$ac_uvar_editfile
    echo '"' >>$ac_uvar_editfile
)dnl
fi
fi
])dnl
dnl
dnl -----------
dnl 
define(AC_UVAR_SETCHKQUOTE,[dnl
if test -z "[$]$1"; then
AC_UVAR_SET($1, $2) dnl
else
if test .[$]$1 = .NONE; then
AC_UVAR_SET($1, $2) dnl
else
AC_SUBST($1)dnl
AC_UVAR_CODE(dnl
    echo -n '$1="' >>$ac_uvar_editfile
    echo -n "$2" >>$ac_uvar_editfile
    echo '"' >>$ac_uvar_editfile
)dnl
fi
fi
])dnl
dnl
dnl -----------
dnl
define(AC_UVAR_OUTPUT,[dnl
AC_UVAR_CODE(dnl
cat >>$ac_uvar_editfile <<'EOF'

##EOF##
EOF
if test x$withval = xyes ; then
    ${EDITOR-vi} $ac_uvar_editfile
    . $ac_uvar_editfile
else
    if test -r $withval ; then
        cp $withval $ac_uvar_editfile
        ${EDITOR-vi} $ac_uvar_editfile
        . $ac_uvar_editfile
        cp $ac_uvar_editfile $withval
    else
        ${EDITOR-vi} $ac_uvar_editfile
        . $ac_uvar_editfile
        cp $ac_uvar_editfile $withval
    fi
fi
rm -f $ac_uvar_editfile
)dnl
])dnl
dnl 
dnl 
dnl
dnl ##########################################################
dnl ##
dnl ##  check for existence of HAVE_SYSEXISTS definitions
dnl ##
dnl ##########################################################
dnl
dnl
define(AC_EXRC,[dnl
dnl -> HAVE_EXRC
])dnl
dnl
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  check for ANSI compiler
dnl ##
dnl ##  Copyright (C) 1992, 1994 Free Software Foundation, Inc.
dnl ##  Francois Pinard <pinard@iro.umontreal.ca>, 1992.
dnl ##  Check for function prototypes.  Including a few ideas from
dnl ##  Brook G. Milligan <brook@trillium.botany.utexas.edu>.
dnl ##
dnl ##  taken from shar-4.0's aclocal.m4
dnl ##
dnl ##########################################################
dnl
AC_DEFUN(AC_C_PROTOTYPES,
[AC_MSG_CHECKING([for function prototypes])
AC_CACHE_VAL(ac_cv_c_prototypes,
[AC_TRY_LINK([#ifndef __STDC__
Syntax Error
#endif], [extern int test (int i, double x);
struct s1 {int (*f) (int a);};
struct s2 {int (*f) (double a);};],
  ac_cv_c_prototypes=yes, ac_cv_c_prototypes=no)])dnl
AC_MSG_RESULT([$ac_cv_c_prototypes])
if test $ac_cv_c_prototypes = yes; then
  AC_DEFINE(HAVE_PROTOTYPES)
  ANSI_CC=yes
else
  ANSI_CC=no
fi
AC_SUBST(ANSI_CC)
])dnl
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  check for supported system type
dnl ##
dnl ##########################################################
dnl
dnl
AC_DEFUN(AC_SUPPORTED_CANONICAL_SYSTEM,[dnl
AC_REQUIRE([AC_CONFIG_AUX_DIR_DEFAULT])dnl

ac_config_sup=$ac_aux_dir/config.sup

AC_MSG_CHECKING(for supported host   system type)
host=`$ac_config_sup $host_alias`
host_cpu=`echo $host | sed 's/^\(.*\)-\(.*\)-\(.*\)$/\1/'`
host_vendor=`echo $host | sed 's/^\(.*\)-\(.*\)-\(.*\)$/\2/'`
host_os=`echo $host | sed 's/^\(.*\)-\(.*\)-\(.*\)$/\3/'`
AC_MSG_RESULT($host)

AC_MSG_CHECKING(for supported target system type)
target=`$ac_config_sup $target_alias`
target_cpu=`echo $target | sed 's/^\(.*\)-\(.*\)-\(.*\)$/\1/'`
target_vendor=`echo $target | sed 's/^\(.*\)-\(.*\)-\(.*\)$/\2/'`
target_os=`echo $target | sed 's/^\(.*\)-\(.*\)-\(.*\)$/\3/'`
AC_MSG_RESULT($target)

AC_MSG_CHECKING(for supported build  system type)
build=`$ac_config_sup $build_alias`
build_cpu=`echo $build | sed 's/^\(.*\)-\(.*\)-\(.*\)$/\1/'`
build_vendor=`echo $build | sed 's/^\(.*\)-\(.*\)-\(.*\)$/\2/'`
build_os=`echo $build | sed 's/^\(.*\)-\(.*\)-\(.*\)$/\3/'`
AC_MSG_RESULT($build)

ac_config_hc_dir=config

if test -r ${ac_config_hc_dir}/cpu-${host_cpu}.h; then
	host_cpu_H=1
else
	host_cpu_H=0
fi
if test -r ${ac_config_hc_dir}/cpu-${host_cpu}.c; then
	host_cpu_C=1
else
	host_cpu_C=0
fi

if test -r ${ac_config_hc_dir}/vendor-${host_vendor}.h; then
	host_vendor_H=1
else
	host_vendor_H=0
fi
if test -r ${ac_config_hc_dir}/vendor-${host_vendor}.c; then
	host_vendor_C=1
else
	host_vendor_C=0
fi

if test -r ${ac_config_hc_dir}/os-${host_os}.h; then
	host_os_H=1
else
	host_os_H=0
fi
if test -r ${ac_config_hc_dir}/os-${host_os}.c; then
	host_os_C=1
else
	host_os_C=0
fi
AC_SUBST(host_cpu_H)
AC_SUBST(host_cpu_C)
AC_SUBST(host_vendor_H)
AC_SUBST(host_vendor_C)
AC_SUBST(host_os_H)
AC_SUBST(host_os_C)
])dnl
dnl
dnl
dnl
define(AC_CONFIG_PARAMS,[dnl

AC_MSG_CHECKING(for name of user)
confuser="$LOGNAME"
AC_MSG_RESULT($confuser)
AC_SUBST(confuser)

AC_MSG_CHECKING(for name of host)
confhost="`uname -n`"
AC_MSG_RESULT($confhost)
AC_SUBST(confhost)

AC_MSG_CHECKING(for current date)
confdate="`date`"
AC_MSG_RESULT($confdate)
AC_SUBST(confdate)

])dnl
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  check for fixed distribution tree and fix it if needed
dnl ##
dnl ##########################################################
dnl
dnl
AC_DEFUN(AC_FIX_DIST_TREE,[dnl
AC_REQUIRE([AC_CONFIG_AUX_DIR_DEFAULT])dnl

ac_fixdist=$ac_aux_dir/fixdist

AC_MSG_CHECKING(for fixed distribution)
# Make sure we can run fixdist
if $ac_fixdist -t >/dev/null 2>&1; then
    AC_MSG_RESULT(already fixed tree)
else
    AC_MSG_RESULT(vanilla tree => fixing...)
    $ac_fixdist
fi
])dnl
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  check for generation mode: production or debug
dnl ##
dnl ##########################################################
dnl
dnl
define(AC_GENMODE,[dnl
AC_MSG_CHECKING(genmode)
AC_ARG_ENABLE(production,dnl
[  --enable-production     to enable procution code and disable debug],
GENMODE=production
CFLAGS="-O"
CXXFLAGS="-O"
LDFLAGS="-O"
LDXXFLAGS="-O"
if test X$GCC = Xyes; then
    CFLAGS="$CFLAGS -pipe"
    CXXFLAGS="$CXXFLAGS -pipe"
fi
,
GENMODE=debug
CFLAGS="-DDEBUG -g"
CXXFLAGS="-DDEBUG -g"
LDFLAGS="-g"
LDXXFLAGS="-g"
if test X$GCC = Xyes; then
    CFLAGS="$CFLAGS -ggdb3 -pipe"
    CXXFLAGS="$CXXFLAGS -ggdb3 -pipe"
	LDFLAGS="$LDFLAGS -ggdb3"
	LDXXFLAGS="$LDXXFLAGS -ggdb3"
fi
)dnl
AC_SUBST(CFLAGS)
AC_SUBST(CXXFLAGS)
AC_SUBST(LDFLAGS)
AC_SUBST(LDXXFLAGS)
AC_SUBST(GENMODE)
AC_MSG_RESULT($GENMODE)
])dnl
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  Startup Message
dnl ##
dnl ##########################################################
dnl
define(AC_STARTUP_MSG,[dnl
X=`cat Laby/Src/Config/Version.c | sed -e '1,/GNUVersion/d' | head -1 | sed -e 's/^ *"//' | sed -e 's/"; *$//'`
AC_MSG_RESULT(Configuring $X)
])dnl
dnl
define(AC_CONFIGURE_PART,[dnl
AC_MSG_RESULT()
AC_MSG_RESULT(__ $1 __)
])dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  GNU Make detection
dnl ##
dnl ##########################################################
dnl
define(AC_IS_GNU_MAKE,[dnl
AC_MSG_CHECKING([whether your default make program is GNU make])
if test ".`make -v 2>/dev/null | grep 'GNU Make'`" = . ; then
	IS_GNU_MAKE=0
	STATIC_MFLAGS=""
    AC_MSG_RESULT([no, but that's ok])
else
	IS_GNU_MAKE=1
	STATIC_MFLAGS="--no-print-directory"
    AC_MSG_RESULT([yes, fine but overkill])
fi
AC_SUBST(IS_GNU_MAKE)
AC_SUBST(STATIC_MFLAGS)
])dnl
dnl
dnl #######
define(AC_INIT_BINSH,
[#! /bin/sh
#  AAA
])
dnl
dnl ##########################################################
dnl ##
dnl ##  Built Environment
dnl ##
dnl ##########################################################
dnl
define(AC_BUILD_USER,[dnl
AC_MSG_CHECKING(for build user)
username="$LOGNAME"
if test ".$username" = .; then
    username="$USER"
    if test ".$username" = .; then
        username="`whoami 2>/dev/null | sed -e 's/\n$//'`"
        if test ".$username" = .; then
            username="`who am i 2>/dev/null | cut '-d ' -f1`"
            if test ".$username" = .; then
                username="unknown"
            fi
        fi
    fi
fi
hostname="`uname -n | sed -e 's/\n$//'`"
if test ".$hostname" = .; then
    hostname="`hostname | sed -e 's/\n$//'`"
    if test ".$hostname" = .; then
        hostname="unknown"
    fi
fi
hostname="`echo $hostname | sed -e 's/\..*//' -e 's/\n$//'`"
if test -f /etc/resolv.conf; then
    domainname="`grep domain /etc/resolv.conf | sed -e 's/.*domain//' -e 's/^ *//' -e 's/^	*//' -e 's/^\.//' -e 's/^/./'`"
    if test ".$domainname" = .; then
        domainname="`grep search /etc/resolv.conf | sed -e 's/.*search//' -e 's/^ *//' -e 's/^	*//' -e 's/ .*//'`"
    fi
else
    domainname="";
fi
domainname="`echo $domainname | sed -e 's/\n$//'`"
build_user="$username@$hostname$domainname"
AC_SUBST(build_user)
AC_MSG_RESULT($build_user)
])dnl
define(AC_BUILD_TIME,[dnl
AC_MSG_CHECKING(for build time)
build_time_ctime="`date | sed -e 's/\n$//'`"
build_time_iso="`date '+%d-%b-%Y' 2>/dev/null | sed -e 's/\n$//'`"
dnl # SunOS has no %b/%Y... ARGL!
if test ".$build_time_iso" = .; then
    build_time_iso="`date '+%d-%m-19%y' | sed -e 's/\n$//'`"
fi
AC_MSG_RESULT($build_time_iso)
AC_SUBST(build_time_ctime)
AC_SUBST(build_time_iso)
])dnl
dnl
