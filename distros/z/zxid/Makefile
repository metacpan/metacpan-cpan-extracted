# zxid/Makefile  -  How to build ZXID (try: make help)
# Copyright (c) 2012-2016 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
# Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
# Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
# Author: Sampo Kellomaki (sampo@iki.fi)
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id: Makefile,v 1.154 2010-01-08 02:10:09 sampo Exp $
# 15.10.2006, refactor sources to be per namespace --Sampo
# 19.1.2006, added new zxid_simple() / Hello World targets and JNI --Sampo
# 26.2.2007, tweaks for the great SOAP merger, WSC support --Sampo
# 3.3.2007,  added many service schemata --Sampo
# 22.2.2008, added mod_auth_saml --Sampo
# 14.4.2008, added SAML POST-SimpleSign binding and Orange APIs --Sampo
# 25.8.2009, added improvements from TAS3 workshop in Lisbon --Sampo
# 29.8.2009, merged in smime support --Sampo
# 15.9.2009, added TAS3 packaging --Sampo
# 14.11.2009, added yubikey support --Sampo
# 12.2.2010, added pthread support --Sampo
# 25.2.2010, added gcov support --Sampo
# 15.9.2010, major hacking to support win32cl (MSVC cl compiler, link (ld), and lib (ar) --Sampo
# 6.2.2012,  improved multiple config support --Sampo
# 16.8.2012, added zxbusd build --Sampo
# 16.4.2013, added diet64 statically linked targets --Sampo
# 21.6.2013, added mini_httpd --Sampo
# 4.11.2013, reformed the TARGET system; include and lib paths per Debian --Sampo
# 21.11.2013, added zxid_httpd --Sampo
# 9.2.2014,  added musl-libc compile --Sampo
# 29.5.2015  upgraded the version due to addition of two factor authentication --Sampo
#
# Build so far only tested on Linux, Solaris 8, MacOS 10.3, and mingw-w64. This
# makefile needs gmake-3.78 or newer.
# (See dietlibc (fefe.de) Makefile for some useful wizardry.)
# Try `make help'
#
# N.B. Before you edit this file, consider overriding select options in
#      localconf.mk (see below for details).
#
# gcc's '-ffunction-sections' + '-fdata-sections' options. (dead code elimn.)

vpath %.c ../zxid
vpath %.h ../zxid

### This is the authorative spot to set version number. Document in Changes file.
### c/zxidvers.h is generated from these, see `make updatevers'
ZXIDVERSION=0x000142
ZXIDREL=1.42

TOP=$(shell pwd)

### Where package is installed (use `make PREFIX=/your/path' to change)
PREFIX=/var/zxid/$(ZXIDREL)

### Where runtime configuration and temporary data is kept.
### If you change the following, be sure to edit zxidconf.h as
### well. N.B. Trailing / (forward slash) is needed.
ZXID_PATH=/var/zxid/

###
### Module selection options (you should enable all, unless building embedded)
###

ENA_SSO=1
ENA_SAML2=1
ENA_FF12=1
ENA_SAML11=1
ENA_WSF=1
ENA_WSF2=1
ENA_WSF11=1
ENA_XACML2=1
ENA_WST=1
ENA_ZXID_HTTPD=1
ENA_SMIME=1
ENA_TAS3=1

### You may supply additional defines on command line.
###   make CDEF='-DZXID_CONF_PATH="/opt/zxid/zxid.conf"'

# Advise other software, such as mini_httpd, to use ZXID specific features
CDEF+= -DUSE_ZXID -DUSE_SSL
# Without cURL the Artifact Profile, WSC, and metadata fetch features are disabled.
CDEF+= -DUSE_CURL
# Without OpenSSL signing and signature verification are not possible
CDEF+= -DUSE_OPENSSL

### The CDEF variable can be later overridden or modified in
### one of the target sections or after all in localconf.mk
### The CDEF is used for dependency computation. For actual
### compilation it is added to CFLAGS.

### Environment dependent options and dependency packages.
### The default values are according to their usual locations
### in Ubuntu and Debian based Linux distributions.

# Try find / -name ap_config.h; find / -name apr.h; find / -name mod_auth_basic.so
# apt-get install libapr1-dev
# apt-get install apache2-dev
APACHE_INC ?= -I/usr/include/apache2
APR_INC    ?= -I/usr/include/apr-1.0
APACHE_MODULES ?= /usr/lib/apache2/modules
DIET_ROOT?=/usr/local/dietlibc-0.33
PHP_CONFIG?=php-config
CSHARP_CONFIG?=true
PY_CONFIG?=true
RUBY_CONFIG?=true

###
### Java options (watch out javac running out of heap)
###

JAR?=jar
JAVAC?=javac
JAVAC_FLAGS?=-J-Xmx128m -classpath . -g
ZXIDJNI_SO?=zxidjava/libzxidjni.so
# JNI library name is very platform dependent (see macosx and mingw)
# find / -name jni.h; find / -name jni_md.h
# apt-get install openjdk-6-jdk
#JNI_INC?=-I/usr/java/include -I/usr/java/include/linux
#JNI_INC?=-I/usr/lib/jvm/java-6-openjdk/include -I/usr/lib/jvm/java-6-openjdk/include/linux
JNI_INC?=-I/usr/lib/jvm/java-6-openjdk-amd64/include -I/usr/lib/jvm/java-6-openjdk-amd64/include/linux
#JNI_INC?=-I/usr/lib/jvm/java-6-openjdk-i386/include -I/usr/lib/jvm/java-6-openjdk-i386/include/linux
#JNI_INC?=-I/usr/lib/jvm/java-6-openjdk-amd64/include -I/usr/lib/jvm/java-6-openjdk-amd64/include/linux
# Path where HttpServlet supplied by your application server resides
# find / -name 'servlet*api*.jar'
# sudo apt-get install tomcat6
SERVLET_PATH=/usr/share/tomcat6/lib/servlet-api.jar
#SERVLET_PATH=../apache-tomcat-5.5.20/common/lib/servlet-api.jar
#SERVLET_PATH=../apache-tomcat-6.0.18/lib/servlet-api.jar

### You may supply additional include paths on command line.
### For example if you compiled the openssl and libcurl from original
### sources, you might specify:
###   make CINC='-I/usr/local/include -I/usr/local/ssl/include'
CINC+=-I. -I$(TOP)
### This CINC variable can be later overridden or modified in
### localconf.mk or in one of the target sections. The CINC is
### used for dependency computation. For actual compilation it
### is added to CFLAGS.

### You may supply additional libs and library paths from the command line.
### For example if you compiled the openssl and libcurl from original
### sources, you might specify:
###   make LIBS='-L/usr/local/lib -L/usr/local/ssl/lib'
### If you need some special platform dependent libraries afterwards,
### supply them using POSTLIBS, e.g.
###   make POSTLIBS='-lxnet -lsocket'
LIBS+= -lcurl -lssl -lcrypto -lz $(POSTLIBS)
#LIBS+= -lpthread -static -lcurl -lssl -lcrypto -lz -dynamic
#LIBS+= -lidn -lrt
#LIBS+= -ldl
### This LIBS variable can be later overridden or modified in
### localconf.mk or in one of the target sections.

### Where commands for build are found (override for cross compiler or Windows)

#CC=ccache gcc
CC=gcc
# If you want to override LD setting you must supply LD_ALT on command line or use localconf.mk
LD_ALT?=$(CC)
LD=$(LD_ALT)
ARC?=ar -crs
ARX?=ar -x
STRIP?=strip
GCOV?=gcov
LCOV?=lcov
ECHO?=echo
CP?=cp
PERL?=perl
XSD2SG_PL?= ../pd/xsd2sg.pl
XSD2SG?=$(PERL) $(XSD2SG_PL)
PD2TEX_PL?= ../pd/pd2tex
PD2TEX?=$(PERL) $(PD2TEX_PL)
PULVERIZE=$(PERL) ./pulverize.pl
GPERF?=gperf
SWIG?=swig
GENHTML?=genhtml

#SHARED_FLAGS=-shared --export-all-symbols -Wl,--whole-archive -Wl,--allow-multiple-definition
# --export-all-symbols does not seem to work on gcc-4.6.1... try -Wl,--export-dynamic instead
SHARED_FLAGS=-shared -Wl,--export-dynamic -Wl,--whole-archive -Wl,--allow-multiple-definition
SHARED_CLOSE=-Wl,--no-whole-archive
### Form CFLAGS from its components
CDEF+= -D_REENTRANT -DDEBUG
CDEF+= -DMUTEX_DEBUG=1
CFLAGS+= -g -fPIC -fno-strict-aliasing
#CFLAGS += -Os    # gcc-3.4.6 miscompiles with -Os on ix86 (2010 --Sampo)
CFLAGS+= -fmessage-length=0
CFLAGS+= -Wall -Wno-parentheses -Wno-unused-label -Wno-unknown-pragmas -Wno-char-subscripts
#LDFLAGS += -Wl,--gc-sections
LIBZXID_A?=libzxid.a
LIBZXID?=-L. -lzxid
PLATFORM_OBJ?=
OUTOPT?=-o 
OBJ_EXT?=o
EXE?=
SO?=.so

ifeq ($(ENA_PG),1)
### To compile for profiling your should run make ENA_PG=1
### See also: make gcov, make lcov (and lcovhtml directory), man gcov, man gprof
### N.B. ccache seems to be incompatible with profiling.
$(info Profiling build)
CFLAGS+= -pg -ftest-coverage -fprofile-arcs
LDFLAGS+= -pg -ftest-coverage -fprofile-arcs
else
# -ffunction-sections is incompatible with profiling
CFLAGS+= -ffunction-sections -fdata-sections
# Following ld flags as well as C flag -ffunction-sections are a quest to
# eliminate unused functions from final link.
#LDFLAGS= -Wl,-O -Wl,2 --gc-sections
endif

####################################################################
### Platform dependent options (choose one with `make TARGET=foo')
###

ifeq ($(TARGET),)
# Target guesser (only works for native builds and only of output of uname is the target name)
TARGET=$(shell uname)
$(warning Guessed TARGET=$(TARGET))
endif

ifeq ($(TARGET),Linux)
### Flags for Linux 2.6 native compile (gcc + gnu binutils)
CDEF+=-DLINUX
# Using PTHREAD helps to avoid problems in multithreaded programs, such as Java servlets
CDEF+= -DUSE_PTHREAD -pthread
ifeq ($(DISTRO),fedora)
CDEF+=-DFEDORA
endif
LIBS+=-lpthread
SO_LIBS+=$(LIBS)
# Marks that target has been detected
TARGET_FOUND=1
endif

ifeq ($(TARGET),diet-linux)
CROSS_COMPILE=1
DIETDIR=/usr/local/dietlibc-0.33
CC=$(DIETDIR)/bin/diet gcc
LD=$(DIETDIR)/bin/diet gcc
CDEF+=-DLINUX
# Using PTHREAD helps to avoid problems in multithreaded programs, such as Java servlets
CDEF+= -DUSE_PTHREAD -pthread
CINC= -I. -I$(DIETDIR)/include
# -fno-stack-protector is needed to eliminate unwanted function plrologue code that causes segv
CFLAGS+= -fno-stack-protector
LDFLAGS= -L$(DIETDIR)/lib-i386 -L$(DIETDIR)/lib
LIBS+=-lpthread
# Marks that target has been detected
TARGET_FOUND=1
endif

ifeq ($(TARGET),musl-linux)
CROSS_COMPILE=1
MUSLDIR=/usr/local/musl-0.9.15
CC=$(MUSLDIR)/bin/musl-gcc
LD=$(MUSLDIR)/bin/musl-gcc
CDEF+=-DLINUX
# Using PTHREAD helps to avoid problems in multithreaded programs, such as Java servlets
CDEF+= -DUSE_PTHREAD -pthread
CINC= -I. -I$(MUSLDIR)/include
# -fno-stack-protector is needed to eliminate unwanted function plrologue code that causes segv
CFLAGS+= -fno-stack-protector
LDFLAGS= -L$(MUSLDIR)/lib-i386 -L$(MUSLDIR)/lib
LIBS+=-lpthread
# Marks that target has been detected
TARGET_FOUND=1
endif

ifeq ($(TARGET),xsol8)
### Cross compilation for Solaris 8 target (on Linux host). Invoke as `make TARGET=xsol8'
# You must have the cross compiler installed in /apps/gcc/sol8 and in path. Similarily
# the cross binutils must be in path.
#    export PATH=/apps/gcc/sol8/bin:/apps/binutils/sol8/bin:$PATH

SYSROOT=/apps/gcc/sol8/sysroot
CROSS_COMPILE=1
CC=sparc-sun-solaris2.8-gcc
LD=sparc-sun-solaris2.8-gcc
CDEF+=-DSUNOS -DBYTE_ORDER=4321 -DBIG_ENDIAN=4321
# Using PTHREAD helps to avoid problems in multithreaded programs, such as Java servlets
CDEF+= -DUSE_PTHREAD -pthread
LIBS+=-lxnet -lsocket
SO_LIBS+=$(LIBS)
TARGET_FOUND=1
endif

ifeq ($(TARGET),sol8)
### Flags for Solaris 8 native compile (with gc and gnu binutils) (BIG_ENDIAN BYTE_ORDER)
CDEF+=-DSUNOS -DBYTE_ORDER=4321 -DBIG_ENDIAN=4321 -I/opt/sfw/include -I/usr/sfw/include
# Using PTHREAD helps to avoid problems in multithreaded programs, such as Java servlets
CDEF+= -DUSE_PTHREAD -pthread
LIBS=-R/opt/sfw/lib -R/usr/sfw/lib -lcurl -lssl -lcrypto -lz -lxnet -lsocket
SO_LIBS+=$(LIBS)
SHARED_FLAGS=-shared --export-all-symbols -Wl,-z -Wl,allextract
SHARED_CLOSE=-Wl,-z -Wl,defaultextract
TARGET_FOUND=1
endif

ifeq ($(TARGET),sol8x86)
# Flags for Solaris 8/x86 native compile (with gc and gnu binutils) (LITTLE_ENDIAN BYTE_ORDER)
CDEF+=-DSUNOS -DBYTE_ORDER=1234 -I/opt/sfw/include -I/usr/sfw/include
# Using PTHREAD helps to avoid problems in multithreaded programs, such as Java servlets
CDEF+= -DUSE_PTHREAD -pthread
LIBS=-R/opt/sfw/lib -R/usr/sfw/lib -lcurl -lssl -lcrypto -lz  -lxnet -lsocket
SO_LIBS+=$(LIBS)
SHARED_FLAGS=-shared --export-all-symbols -Wl,-z -Wl,allextract
SHARED_CLOSE=-Wl,-z -Wl,defaultextract
endif

ifeq ($(TARGET),macosx)
#### Flags for MacOS 10 / Darwin native compile (gcc + Apple linker)
#   alias ldd='otool -L'
#   alias strace=ktrace or dtrace or dtruss
CFLAGS=-g -fPIC -fmessage-length=0 -Wno-unused-label -Wno-unknown-pragmas -fno-strict-aliasing -DMAYBE_UNUSED=''
CDEF+=-DMACOSX
# Using PTHREAD helps to avoid problems in multithreaded programs, such as Java servlets
CDEF+= -DUSE_PTHREAD -pthread
JNI_INC=-I/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Headers
SHARED_FLAGS=-dylib -all_load -bundle
SHARED_CLOSE=
SO_LIBS+=$(LIBS)
ZXIDJNI_SO=zxidjava/libzxidjni.jnilib
#SHARED_FLAGS=-dylib -all_load -keep_private_externs 
#OPENSSL_ROOT=/Developer/SDKs/MacOSX10.4u.sdk/usr
#CURL_ROOT=/Developer/SDKs/MacOSX10.4u.sdk/usr
# Try find / -name ap_config.h; find / -name apr.h
APACHE_INC = -I/Developer/SDKs/MacOSX10.6.sdk/usr/include/apache2
APR_INC    = -I/Developer/SDKs/MacOSX10.6.sdk/usr/include/apr-1
APACHE_MODULES = /usr/libexec/apache2
MOD_AUTH_SAML_LIBS=-lapr-1
#  -lhttpd2core
TARGET_FOUND=1
endif

ifeq ($(TARGET),FreeBSD)
# Some freebsd guesses result "FreeBSD" so we map it to "freebsd"
TARGET=freebsd
endif
ifeq ($(TARGET),freebsd)
### Putative flags for Freebsd compile
CDEF+=-DFREEBSD
# Using PTHREAD helps to avoid problems in multithreaded programs, such as Java servlets
CDEF+= -DUSE_PTHREAD -pthread
LIBS+=-lpthread
SO_LIBS+=$(LIBS)
TARGET_FOUND=1
endif

ifeq ($(TARGET),CYGWIN_NT-6.1)
TARGET=cygwin
endif

ifeq ($(TARGET),cygwin)
### Native Windows build using Cygwin environment and gcc
CDEF+=-DCYGWIN -DUSE_LOCK=dummy_no_flock -DCURL_STATICLIB -DLOCK_UN=0
MOD_AUTH_SAML_LIBS=-lapr-1 -lhttpd2core
SO_LIBS+=$(LIBS)
TARGET_FOUND=1
endif

ifeq ($(TARGET),mingw)
### These options work with late 2010 vintage mingw (x86-mingw32-build-1.0-sh.tar.bz2?)
CP=ln
ZXID_PATH=/c/zxid/
EXE=.exe
SO=.dll
PRECHECK_PREP=precheck_prep_win
CDEF+=-DMINGW -DUSE_LOCK=dummy_no_flock -DCURL_STATICLIB -DUSE_PTHREAD
SO_LIBS= -L/mingw/lib -lcurl -lssl -lcrypto -lz -lssh2 -lidn -lwldap32 -lgdi32 -lwsock32 -lwinmm -lkernel32 -lz
LIBS= -mconsole $(SO_LIBS) -lpthread
# --dll  -mdll
SHARED_FLAGS= -mdll -Wl,--add-stdcall-alias -static -Wl,--export-all-symbols -Wl,--whole-archive -Wl,-no-undefined -Wl,--enable-runtime-pseudo-reloc -Wl,--allow-multiple-definition
CFLAGS=-g -fmessage-length=0 -Wno-unused-label -Wno-unknown-pragmas -fno-strict-aliasing -mno-cygwin -D'ZXID_PATH="$(ZXID_PATH)"'
#JNI_INC=-I"C:/Program Files/Java/jdk1.5.0_14/include" -I"C:/Program Files/Java/jdk1.5.0_14/include/win32"
JNI_INC=-I"/cygdrive/c/Program Files (x86)/Java/jdk1.7.0_21/include/" -I"/cygdrive/c/Program Files (x86)/Java/jdk1.7.0_21/include/win32/"
ZXIDJNI_SO=zxidjava/zxidjni.dll
ifeq ($(SHARED),1)
LIBZXID=-L. -lzxiddll
endif
TARGET_FOUND=1
endif

ifeq ($(TARGET),xmingw)
### Cross compilation for MINGW 32bit target (on Linux host).
# Invoke as `make zxid.dll TARGET=xmingw'
# You must have the cross compiler installed in /apps/gcc/mingw and in
# path. Similarily the cross binutils must be in path.
#    export PATH=/apps/gcc/mingw/bin:/apps/binutils/mingw/bin:$PATH
#
# For best results use the same cross compiler for compiling the dependency
# libraries like curl, openssl, and zlib. Furthermore: your cross compiler
# should be for MinGW target, not for Cygwin (i.e. default compiler of Cygwin
# may have trouble due to linking against cygwin dependent libraries).
#
# Cross compiling curl
#   CPPFLAGS='-I/apps/gcc/mingw/sysroot/include' LDFLAGS='-L/apps/gcc/mingw/sysroot/lib' LIBS='-lz' ./configure --prefix=/usr --with-ssl=/apps/gcc/mingw/sysroot --without-gnutls --enable-thread --enable-nonblocking --host=i586-pc-mingw32 --with-random=/random.txt --disable-shared --enable-static
#   # Despite apparent misdetection of ar, the compile finishes
#   make
#   cp lib/.libs/libcurl* /apps/gcc/mingw/sysroot/lib
#   cp -r include/curl/ /apps/gcc/mingw/sysroot/include
#
# Symbol hunting
#   undefined reference to `WinMain@16'               --> add -Wl,--no-whole-archive after all libs
#   undefined reference to `_imp__curl_easy_setopt'   --> compile with -DCURL_STATICLIB
#   undefined reference to `_imp__curl_easy_strerror' --> compile with -DCURL_STATICLIB
#   undefined reference to `timeGetTime@0'            --> add -lwinmm

MINGWDIR=/apps/gcc/mingw
SYSROOT=$(MINGWDIR)/sysroot
CROSS_COMPILE=1
EXE=.exe
SO=.dll
CC=$(MINGWDIR)/bin/i586-pc-mingw32-gcc
LD=$(MINGWDIR)/bin/i586-pc-mingw32-gcc
ARC=/apps/binutils/mingw/bin/i586-pc-mingw32-ar -crs
ARX=/apps/binutils/mingw/bin/i586-pc-mingw32-ar -x
PRECHECK_PREP=precheck_prep_win
#CDEF+=-DMINGW -DUSE_LOCK=flock -DCURL_STATICLIB
CDEF+=-DMINGW -DUSE_LOCK=dummy_no_flock -DCURL_STATICLIB -DUSE_PTHREAD
# All dependency libraries are assumed to be in the mingw environment
CINC=-I. -I$(TOP) -I$(SYSROOT)/include
APACHE_INC = -I$(SYSROOT)/include
APR_INC    = -I$(SYSROOT)/srclib/apr-util/include
ZXIDJNI_SO=zxidjava/zxidjni.dll
ifeq ($(SHARED),1)
LIBZXID=-L. -lzxiddll
endif
# -lws2_32  -lmingw32  -u _imp__curl_easy_setopt -u _imp__curl_easy_strerror
SO_LIBS= -L$(SYSROOT)/lib -lcurl -lssl -lcrypto -lz -lwinmm -lwsock32 -lgdi32 -lkernel32
LIBS= -mconsole $(SO_LIBS)
# --dll  -mdll
#SHARED_FLAGS=-shared --export-all-symbols -Wl,--whole-archive -Wl,-no-undefined -Wl,--enable-runtime-reloc -Wl,--whole-archive
SHARED_FLAGS= -shared -Wl,--add-stdcall-alias --export-all-symbols -Wl,--whole-archive -Wl,-no-undefined -Wl,--enable-runtime-pseudo-reloc -Wl,--allow-multiple-definition
CFLAGS=-g -fmessage-length=0 -Wno-unused-label -Wno-unknown-pragmas -fno-strict-aliasing -mno-cygwin

# java.lang.UnsatisfiedLinkError: Given procedure could not be found
# -mno-cygwin -mrtd -Wl,--kill-at -Wl,--add-stdcall-alias
# http://www.inonit.com/cygwin/jni/helloWorld/c.html
# http://www.1702.org/jniswigdll.html
# http://maba.wordpress.com/2004/07/28/generating-dll-files-for-jni-under-windowscygwingcc/

#/apps/gcc/mingw/bin/i586-pc-mingw32-gcc -o zxid.dll -Wl,--add-stdcall-alias -shared --export-all-symbols -Wl,-whole-archive -Wl,-no-undefined -Wl,--enable-runtime-pseudo-reloc -Wl,--allow-multiple-definition -Wl,--output-def,zxid.def,--out-implib,zxidimp.lib libzxid.a -Wl,-no-whole-archive -L/apps/gcc/mingw/sysroot/lib -L/apps/gcc/mingw/sysroot/lib -lcurl -lssl -lcrypto -lz -lwinmm -lwsock32 -lgdi32 -lkernel32 -mdll
#i586-pc-mingw32-gcc: shared and mdll are not compatible
#make: *** [zxid.dll] Error 1
# remove the -shared flag and it compiles
TARGET_FOUND=1
endif

ifeq ($(TARGET),xmingw64)
### Cross compilation for MINGW64 target (on Linux host).
# Invoke as `make zxid.dll TARGET=xmingw64'
# You must have the cross compiler installed. You can get one from
# http://mingw-w64.sourceforge.net/download.php
#
# For best results use the same cross compiler for compiling the dependency
# libraries like curl, openssl, and zlib. Furthermore: your cross compiler
# should be for MinGW target, not for Cygwin (i.e. default compiler of Cygwin
# may have trouble due to linking against cygwin dependent libraries).
#
# Cross compiling zlib
#     export PATH=/apps/mingw/mingw-w64-bin_i686-linux_20130523/bin:$PATH
#     ./configure --prefix=/mingw
#     CC=x86_64-w64-mingw32-gcc LD=x86_64-w64-mingw32-ld AR=x86_64-w64-mingw32-ar RANLIB=x86_64-w64-mingw32-gcc-ranlib make -e
#     cp libz.a /apps/mingw/3.0.0-w64/mingw/lib
#     cp zlib.h zconf.h /apps/mingw/3.0.0-w64/mingw/include
#
# Cross compiling openssl
#     ./Configure --prefix=/mingw --cross-compile-prefix=x86_64-w64-mingw32- enable-rc5 enable-mdc2 zlib mingw64-cross-debug -I/apps/mingw/3.0.0-w64/x86_64-w64-mingw32/include
#     #make depend   # error, apparently not needed
#     make
#     # If you have syntax errors with string "<symlink>" then eliminate
#     # symlinks from include/openssl by copying the files directly there.
#     #make test     # not doable since openssl.exe will not execute on Linux
#     cp -Lr include/openssl /apps/mingw/3.0.0-w64/mingw/include
#     cp libssl.a libcrypto.a /apps/mingw/3.0.0-w64/mingw/lib
#     cp apps/openssl.exe /apps/mingw/3.0.0-w64/mingw/bin-w64
#
# Cross compiling curl
#     CPPFLAGS='-I/apps/mingw/3.0.0-w64/mingw/include' LDFLAGS='-L/apps/mingw/3.0.0-w64/mingw/lib' LIBS='-lz' ./configure --prefix=/mingw --with-ssl=/apps/mingw/3.0.0-w64/mingw --without-gnutls -enable-debug --enable-thread --enable-nonblocking --host=x86_64-w64-mingw32 --with-random=/random.txt --disable-shared --enable-static
#     make
#     cp lib/.libs/libcurl* /apps/mingw/3.0.0-w64/mingw/lib
#     cp -r include/curl/ /apps/mingw/3.0.0-w64/mingw/include
#     cp src/curl.exe /apps/mingw/3.0.0-w64/mingw/bin-w64
#
# Fix illegal relocation error on linking libws2_32.a
# wget http://www.dependencywalker.com/depends22_x86.zip
# dependes.exe /c /? zxid_httpd.exe
# psutils

# MinGW-W64 Runtime 3.0 (alpha - rev. 5871) 2013-05-21
MINGWDIR=/apps/mingw/mingw-w64-bin_i686-linux_20130523
SYSROOT=$(MINGWDIR)/x86_64-w64-mingw32
CROSS_COMPILE=1
EXE=.exe
SO=.dll
CC=$(MINGWDIR)/bin/x86_64-w64-mingw32-gcc
LD=$(MINGWDIR)/bin/x86_64-w64-mingw32-gcc
ARC=$(MINGWDIR)/bin/x86_64-w64-mingw32-ar -crs
ARX=$(MINGWDIR)/bin/x86_64-w64-mingw32-ar -x
STRIP=$(MINGWDIR)/bin/x86_64-w64-mingw32-strip
PRECHECK_PREP=precheck_prep_win
#CDEF+=-DMINGW -DUSE_LOCK=flock -DCURL_STATICLIB
CDEF+=-DMINGW -DUSE_LOCK=dummy_no_flock -DCURL_STATICLIB -DUSE_PTHREAD
# All dependency libraries are assumed to be in the mingw environment
CINC=-I. -I$(TOP) -I$(SYSROOT)/include
APACHE_INC = -I$(SYSROOT)/include/apache2
APR_INC    = -I$(SYSROOT)/include/apr-1
JNI_INC=-I$(SYSROOT)/include
ZXIDJNI_SO=zxidjava/zxidjni.dll
ifeq ($(SHARED),1)
LIBZXID=-L. -lzxiddll
endif
# -lws2_32 -lwldap32 -lmingw64 -lcrtdll -u _imp__curl_easy_setopt -u _imp__curl_easy_strerror
SO_LIBS= -L$(SYSROOT)/lib -lcurl -lssl -lcrypto -lz -lws2_32 -lwldap32 -lcrypt32 -lwinmm -lwsock32 -lgdi32 -lkernel32
LIBS= -mconsole $(SO_LIBS)
# --dll  -mdll
#SHARED_FLAGS=-shared --export-all-symbols -Wl,--whole-archive -Wl,-no-undefined -Wl,--enable-runtime-reloc -Wl,--whole-archive
SHARED_FLAGS= -shared -Wl,--add-stdcall-alias -Wl,--whole-archive -Wl,-no-undefined -Wl,--enable-runtime-pseudo-reloc -Wl,--allow-multiple-definition
CFLAGS=-g -fmessage-length=0 -Wno-unused-label -Wno-unknown-pragmas -fno-strict-aliasing
TARGET_FOUND=1
endif

ifeq ($(TARGET),xmingw64b)
### Cross compilation for MINGW64 target (on Ubuntu Linux host).
# Invoke as `make zxid.dll TARGET=xmingw64b'
# This target was tested with Ubuntu/Debian supplied mingw-w64 cross compiler package
#    apt-get install mingw-w64
#
# For best results use the same cross compiler for compiling the dependency
# libraries like curl, openssl, and zlib. Furthermore: your cross compiler
# should be for MinGW target, not for Cygwin (i.e. default compiler of Cygwin
# may have trouble due to linking against cygwin dependent libraries).
#
# Cross compiling zlib
#     export PATH=/usr/bin:/bin
#     ./configure --prefix=/usr/x86_64-w64-mingw32
#     make CC=x86_64-w64-mingw32-gcc LD=x86_64-w64-mingw32-ld AR=x86_64-w64-mingw32-ar RANLIB=x86_64-w64-mingw32-gcc-ranlib
#     # compilation fails when trying to create .so, but the .a has been built by then
#     cp libz.a /usr/x86_64-w64-mingw32/lib
#     cp zlib.h zconf.h /usr/x86_64-w64-mingw32/include
#
# Cross compiling openssl
#     ./Configure --prefix=/usr/x86_64-w64-mingw32 --cross-compile-prefix=x86_64-w64-mingw32- enable-rc5 enable-mdc2 zlib mingw64-cross-debug
#     #make depend   # error, apparently not needed
#     make
#     # If you have syntax errors with string "<symlink>" then eliminate
#     # symlinks from include/openssl by copying the files directly there.
#     #make test     # not doable since openssl.exe will not execute on Linux
#     cp -Lr include/openssl /usr/x86_64-w64-mingw32/include
#     cp libssl.a libcrypto.a /usr/x86_64-w64-mingw32/lib
#     cp apps/openssl.exe /usr/x86_64-w64-mingw32/bin
#
# Cross compiling curl
#     CPPFLAGS='-I/usr/x86_64-w64-mingw32/include' LDFLAGS='-L/usr/x86_64-w64-mingw32/lib' LIBS='-lz' ./configure --prefix=/usr/x86_64-w64-mingw32 --with-ssl=/usr/x86_64-w64-mingw32 --without-gnutls -enable-debug --enable-thread --enable-nonblocking --host=x86_64-w64-mingw32 --with-random=/random.txt --disable-shared --enable-static
#     make
#     cp lib/.libs/libcurl* /usr/x86_64-w64-mingw32/lib
#     cp -r include/curl/ /usr/x86_64-w64-mingw32/include
#     cp src/curl.exe /usr/x86_64-w64-mingw32/bin

# apt-get install mingw-w64
# MinGW-W64 Runtime 1.0 (stable - rev. 0) 0000-00-00
MINGWDIR=/usr
SYSROOT=$(MINGWDIR)/x86_64-w64-mingw32
CROSS_COMPILE=1
EXE=.exe
SO=.dll
CC=$(MINGWDIR)/bin/x86_64-w64-mingw32-gcc
LD=$(MINGWDIR)/bin/x86_64-w64-mingw32-gcc
ARC=$(MINGWDIR)/bin/x86_64-w64-mingw32-ar -crs
ARX=$(MINGWDIR)/bin/x86_64-w64-mingw32-ar -x
PRECHECK_PREP=precheck_prep_win
#CDEF+=-DMINGW -DUSE_LOCK=flock -DCURL_STATICLIB
CDEF+=-DMINGW -DUSE_LOCK=dummy_no_flock -DCURL_STATICLIB -DUSE_PTHREAD
# All dependency libraries are assumed to be in the mingw environment
CINC=-I. -I$(TOP) -I$(SYSROOT)/include
APACHE_INC = -I$(SYSROOT)/include
APR_INC    = -I$(SYSROOT)/srclib/apr-util/include
JNI_INC=-I$(SYSROOT)/include
ZXIDJNI_SO=zxidjava/zxidjni.dll
ifeq ($(SHARED),1)
LIBZXID=-L. -lzxiddll
endif
# -lws2_32 -lwldap32 -lmingw64 -lcrtdll -u _imp__curl_easy_setopt -u _imp__curl_easy_strerror
SO_LIBS= -L$(SYSROOT)/lib -lcurl -lssl -lcrypto -lz -lws2_32 -lwldap32 -lcrypt32 -lwinmm -lwsock32 -lgdi32 -lkernel32
LIBS= -mconsole $(SO_LIBS)
# --dll  -mdll
#SHARED_FLAGS=-shared --export-all-symbols -Wl,--whole-archive -Wl,-no-undefined -Wl,--enable-runtime-reloc -Wl,--whole-archive
SHARED_FLAGS= -shared -Wl,--add-stdcall-alias -Wl,--whole-archive -Wl,-no-undefined -Wl,--enable-runtime-pseudo-reloc -Wl,--allow-multiple-definition
CFLAGS=-g -fmessage-length=0 -Wno-unused-label -Wno-unknown-pragmas -fno-strict-aliasing
TARGET_FOUND=1
endif

ifeq ($(TARGET),win32cl)
### Native Compilation with Microsoft Visual C++ compiler's command line (aka msvc)
CP=copy
CC=cl
LD=link
ARC=lib
CDEF+=-DMINGW -DWIN32CL -DUSE_LOCK=flock -DCURL_STATICLIB -DUSE_PTHREAD
CURL_ROOT="G:/cvsdev/libcurl-7.19.3-win32-ssl-msvc"
OPENSSL_ROOT="C:/OpenSSL"
ZLIB_ROOT="C:/Program Files/GnuWin32"
CINC=-I. -I$(TOP) -I"$(CURL_ROOT)/include" -I"$(OPENSSL_ROOT)/include" -I"$(ZLIB_ROOT)/include"
JNI_INC=-I"C:/Program Files/Java/jdk1.5.0_14/include" -I"C:\Program Files\Java\jdk1.5.0_14\include\win32"
WIN_DDL_LIBS= -LIBPATH:$(CURL_ROOT)/lib/Debug -LIBPATH:$(OPENSSL_ROOT)/lib/VC -LIBPATH:$(ZLIB_ROOT)/lib curllib.lib libeay32MD.lib ssleay32MD.lib zlib.lib kernel32.lib user32.lib winmm.lib Ws2_32.lib
LIBS= $(SO_LIBS)
#SHARED_FLAGS=-LDd -MDd -shared --export-all-symbols
#SHARED_CLOSE=/SUBSYSTEM:WINDOWS
SHARED_FLAGS=-DLL -shared --export-all-symbols
SHARED_CLOSE=
CFLAGS=-Zi -WL -DMAYBE_UNUSED=''
#CFLAGS+=-Yd
OUTOPT=-OUT:
OBJ_EXT=obj
EXE=.exe
SO=.dll
PLATFORM_OBJ=zxdirent.obj
LIBZXID_A=zxid.lib
GPERF=gperf.exe
SHELL="C:\Program Files\GNU Utils\bin"
MAKESHELL="C:\Program Files\GNU Utils\bin"
ZXIDJNI_SO=zxidjava/zxidjni.dll
ifeq ($(SHARED),1)
LIBZXID=-L. -lzxiddll
else
LIBZXID=zxid.lib
endif
TARGET_FOUND=1
endif

ifeq ($(TARGET_FOUND),)
$(error TARGET $(TARGET) not found. Run make help)
endif

### To change any of the above options, you can either supply
### alternate values on make command line, like `make PREFIX=/your/path'
### or you can create localconf.mk file to hold your options. This
### file is included here, but if it's missing, no problem.

-include localconf.mk

####################################################################
### End of platform dependent options (mortals can look, but
### should not edit below this line).

ifeq ($(V),)
$(info Nonverbose build (use make V=1 to enable verbose build).)
$(info TARGET=$(TARGET))
$(info TOP=$(TOP))
$(info CC=$(CC))
$(info CFLAGS=$(CFLAGS))
$(info CDEF=$(CDEF))
$(info CINC=$(CINC))
$(info LD=$(LD))
$(info LDFLAGS=$(LDFLAGS))
$(info LIBS=$(LIBS))
$(info --------------------------)
endif
#CFLAGS += $(CDEF) $(CINC)

# Avoid make's built-in implicit rules and variables; do not print entry msg
.SUFFIXES:
MAKEFLAGS= -rR --no-print-directory

ifeq ($(V),1)

ifeq ($(TARGET),win32cl)
%.obj: %.c
	$(CC) $(CFLAGS) $(CDEF) $(CINC) -Fo$@ -c $<
else
%.$(OBJ_EXT): %.c
	$(CC) $(OUTOPT)$@ -c $< $(CFLAGS) $(CDEF) $(CINC)
endif

%$(EXE): %.$(OBJ_EXT)
	$(LD) $(OUTOPT)$@ $< $(LDFLAGS) $(LIBZXID) $(LIBS)

precheck/%$(EXE): precheck/%.$(OBJ_EXT)
	$(LD) $(OUTOPT)$@ $< $(LDFLAGS) $(LIBS)

else

ifeq ($(TARGET),win32cl)
%.obj: %.c
	@echo "  Compiling $<"
	@if $(CC) $(CFLAGS) $(CDEF) $(CINC) -Fo$@ -c $< ; then : ; else \
	echo Failed command:; echo '$(CC) $(CFLAGS) $(CDEF) $(CINC) -Fo$@ -c $<' ; false; fi
else
%.$(OBJ_EXT): %.c
	@echo "  Compiling $<"
	@if $(CC) $(OUTOPT)$@ -c $< $(CFLAGS) $(CDEF) $(CINC) ; then : ; else \
	echo Failed command:; echo '$(CC) $(OUTOPT)$@ -c $< $(CFLAGS) $(CDEF) $(CINC)' ; false; fi
endif

precheck/chk-%$(EXE): precheck/chk-%.$(OBJ_EXT)
	@echo "  Link exe  $@"
	@if $(LD) $(OUTOPT)$@ $< $(LDFLAGS) $(LIBS) ; then : ; else \
	echo Failed command:; echo '$(LD) $(OUTOPT)$@ $< $(LDFLAGS) $(LIBS)' ; false; fi

%$(EXE): %.$(OBJ_EXT)
	@echo "  Linking   $@"
	@if $(LD) $(OUTOPT)$@ $< $(LDFLAGS) $(LIBZXID) $(LIBS) ; then : ; else \
	echo Failed command:; echo '$(LD) $(OUTOPT)$@ $< $(LDFLAGS) $(LIBZXID) $(LIBS)' ; false; fi

endif

# Avoid funny character set dependencies
unexport LC_ALL
LC_COLLATE=C
LC_NUMERIC=C
export LC_COLLATE LC_NUMERIC

### Start of dependencies and targets

DEFAULT_EXE= zxidhlo$(EXE) zxididp$(EXE) zxidhlowsf$(EXE) zxidsimple$(EXE) zxidwsctool$(EXE) zxlogview$(EXE) zxidhrxmlwsc$(EXE) zxidhrxmlwsp$(EXE) zxdecode$(EXE) zxcot$(EXE) zxpasswd$(EXE) zxcall$(EXE) zxumacall$(EXE) zxencdectest$(EXE)

ALL_EXE= smime$(EXE) zxidwspcgi$(EXE) zxid_httpd$(EXE) htpasswd$(EXE)

#$(info DEFAULT_EXE=$(DEFAULT_EXE))

default: seehelp precheck $(DEFAULT_EXE)

all: default precheck_apache samlmod phpzxid javazxid apachezxid $(ALL_EXE)

all_minus_perl: default precheck_apache apachezxid phpzxid javazxid app_demo.class $(ALL_EXE)

zxbus:  zxbusd zxbustailf zxbuslist

aller: all zxbus app_demo.class

maymay: javazxid app_demo.class

diet64: zxcot-static-x64 zxpasswd-static-x64 zxididp-static-x64 zxidhlo-static-x64 zxlogview-static-x64 zxcall-static-x64 zxumacall-static-x64 zxdecode-static-x64 zxbusd-static-x64 zxbuslist-static-x64 zxbustailf-static-x64

ZXIDHDRS=zx.h zxid.h zxidnoswig.h c/zxidvers.h

ZXID_LIB_OBJ=zxidsimp.$(OBJ_EXT) zxidpool.$(OBJ_EXT) zxidpsso.$(OBJ_EXT) zxidsso.$(OBJ_EXT) zxidslo.$(OBJ_EXT) zxiddec.$(OBJ_EXT) zxidspx.$(OBJ_EXT) zxididpx.$(OBJ_EXT) zxidmni.$(OBJ_EXT) zxidpep.$(OBJ_EXT) zxidpdp.$(OBJ_EXT) zxidmk.$(OBJ_EXT) zxida7n.$(OBJ_EXT) zxidses.$(OBJ_EXT) zxiduser.$(OBJ_EXT) zxidcgi.$(OBJ_EXT) zxidconf.$(OBJ_EXT) zxidecp.$(OBJ_EXT) zxidcdc.$(OBJ_EXT) zxidloc.$(OBJ_EXT) zxidlib.$(OBJ_EXT) zxidmeta.$(OBJ_EXT) zxidmda.$(OBJ_EXT) zxidcurl.$(OBJ_EXT) zxidepr.$(OBJ_EXT) zxida7n.$(OBJ_EXT) ykcrc.$(OBJ_EXT) ykaes.$(OBJ_EXT) $(PLATFORM_OBJ)

ZX_OBJ=c/zx-ns.$(OBJ_EXT) c/zx-attrs.$(OBJ_EXT) c/zx-elems.$(OBJ_EXT) zxlibdec.$(OBJ_EXT) zxlibenc.$(OBJ_EXT) zxlib.$(OBJ_EXT) zxns.$(OBJ_EXT) zxpw.$(OBJ_EXT) zxutil.$(OBJ_EXT) zxbusprod.$(OBJ_EXT) zxlog.$(OBJ_EXT) zxsig.$(OBJ_EXT) zxcrypto.$(OBJ_EXT) akbox_fn.$(OBJ_EXT) match.$(OBJ_EXT) c/license.$(OBJ_EXT)

WSF_OBJ=zxidmkwsf.$(OBJ_EXT) zxidwsf.$(OBJ_EXT) zxidwsc.$(OBJ_EXT) zxidwsp.$(OBJ_EXT) zxiddi.$(OBJ_EXT) zxidim.$(OBJ_EXT) zxidps.$(OBJ_EXT)

OAUTH_OBJ=zxidoauth.$(OBJ_EXT)

SMIME_LIB_OBJ=certauth.$(OBJ_EXT) keygen.$(OBJ_EXT) pkcs12.$(OBJ_EXT) smime-enc.$(OBJ_EXT) smime-qry.$(OBJ_EXT) smime-vfy.$(OBJ_EXT) smimemime.$(OBJ_EXT) smimeutil.$(OBJ_EXT)

ifeq ($(PULVER),1)

# WARNING: THE PULVER OPTIONS ARE NOT CURRENTLY MAINTAINED AND ARE OUT OF DATE!
# Pulverize dependencies. These arrange some source files to be split
# to one-function-per-file format ("pulver") so that GNU ld will only
# pull in those files, i.e. functions, that are actually used. This is
# a workaround for GNU ld not having a dead function elimination
# feature.  You should do `make PULVER=1' for production or
# distribution build of this library as that will ensure smallest
# possible binaries for eventual users of the library.

PULVER_DEPS=pulver/c_saml2_dec_c.deps pulver/c_saml2_enc_c.deps \
	pulver/c_saml2_aux_c.deps pulver/c_saml2_getput_c.deps \
	pulver/c_saml2md_dec_c.deps pulver/c_saml2md_enc_c.deps \
	pulver/c_saml2md_aux_c.deps pulver/c_saml2md_getput_c.deps

c_saml2_dec_c_o=$(shell cat pulver/c_saml2_dec_c.deps)
c_saml2_enc_c_o=$(shell cat pulver/c_saml2_enc_c.deps)
c_saml2_aux_c_o=$(shell cat pulver/c_saml2_aux_c.deps)
c_saml2_getput_c_o=$(shell pulver/c_saml2_getput_c.deps)

#pulver/c_saml2_dec_c.deps $(c_saml2_dec_c_o:.$(OBJ_EXT)=.c): c/saml2-dec.c	

pulver/c_saml2_dec_c.deps: c/saml2-dec.c	
	$(PULVERIZE) pulver c/saml2-dec.c >pulver/c_saml2_dec_c.deps

#pulver/c_saml2_enc_c.deps $(c_saml2_enc_c_o:%.$(OBJ_EXT)=%.c): c/saml2-enc.c	

pulver/c_saml2_enc_c.deps $(foo:%.o=%.c): c/saml2-enc.c	
	$(PULVERIZE) pulver c/saml2-enc.c >pulver/c_saml2_enc_c.deps

pulver/c_saml2_aux_c.deps $(c_saml2_aux_c_o:.o=.c): c/saml2-aux.c	
	$(PULVERIZE) pulver c/saml2-aux.c >pulver/c_saml2_aux_c.deps
pulver/c_saml2_getput_c.deps $(c_saml2_getput_c_o:.o=.c): c/saml2-getput.c	
	$(PULVERIZE) pulver c/saml2-getput.c >pulver/c_saml2_getput_c.deps

c_saml2md_dec_c_o=$(shell cat pulver/c_saml2md_dec_c.deps)
c_saml2md_enc_c_o=$(shell cat pulver/c_saml2md_enc_c.deps)
c_saml2md_aux_c_o=$(shell cat pulver/c_saml2md_aux_c.deps)
c_saml2md_getput_c_o=$(shell pulver/c_saml2md_getput_c.deps)

pulver/c_saml2md_dec_c.deps $(c_saml2md_dec_c_o:.o=.c): c/saml2md-dec.c	
	$(PULVERIZE) pulver c/saml2md-dec.c >pulver/c_saml2md_dec_c.deps
pulver/c_saml2md_enc_c.deps $(c_saml2md_enc_c_o:.o=.c): c/saml2md-enc.c	
	$(PULVERIZE) pulver c/saml2md-enc.c >pulver/c_saml2md_enc_c.deps
pulver/c_saml2md_aux_c.deps $(c_saml2md_aux_c_o:.o=.c): c/saml2md-aux.c	
	$(PULVERIZE) pulver c/saml2md-aux.c >pulver/c_saml2md_aux_c.deps
pulver/c_saml2md_getput_c.deps $(c_saml2md_getput_c_o:.o=.c): c/saml2md-getput.c	
	$(PULVERIZE) pulver c/saml2md-getput.c >pulver/c_saml2md_getput_c.deps

#-include pulver/c_saml2_dec_c.deps
#-include pulver/c_saml2_enc_c.deps
#-include pulver/c_saml2_aux_c.deps
#-include pulver/c_saml2_getput_c.deps

ZX_OBJ += \
  $(c_saml2_dec_c_o)    $(c_saml2md_dec_c_o) \
  $(c_saml2_enc_c_o)    $(c_saml2md_enc_c_o) \
  $(c_saml2_aux_c_o)    $(c_saml2md_aux_c_o) \
  $(c_saml2_getput_c_o) $(c_saml2md_getput_c_o)

else

### Nonpulver deps

ifeq ($(ENA_SSO),1)

# Nonpulverized build. This will result in bigger binaries because gnu ld does
# not understand to do dead function elimination. However, this is faster to build.

#ZX_OBJ +=

endif

ifeq ($(ENA_WSF),1)

#WSF_OBJ +=

endif

endif

ZXBUSD_OBJ=zxbusd.$(OBJ_EXT) hiios.$(OBJ_EXT) hiinit.$(OBJ_EXT) hitodo.$(OBJ_EXT) hinet.$(OBJ_EXT) hiread.$(OBJ_EXT) hiwrite.$(OBJ_EXT) hiiosdump.$(OBJ_EXT) testping.$(OBJ_EXT) http.$(OBJ_EXT) smtp.$(OBJ_EXT) stomp.$(OBJ_EXT) zxbusdist.$(OBJ_EXT) zxbussubs.$(OBJ_EXT) zxbusent.$(OBJ_EXT)

#
# Schemata and potential xml document roots.
# See also sg/wsf-soap11.sg for a place to "glue" new functions in.
# N.B. As of 0.69 implementation, the search to zx_ns_tab is a linear
# scan, so it pays to place commonly referenced namespaces early in ZX_SG.
#

ZX_SG+=sg/xmldsig-core.sg sg/xenc-schema.sg sg/ec.sg

# SAML 2.0

ifeq ($(ENA_SAML2),1)

ZX_SG+=sg/wsf-soap11.sg sg/saml-schema-assertion-2.0.sg sg/saml-schema-protocol-2.0.sg sg/saml-schema-ecp-2.0.sg sg/liberty-paos-v2.0.sg
ZX_ROOTS+=-r sa:Assertion -r sa:EncryptedAssertion -r sa:NameID -r sa:EncryptedID -r sp:NewID -r sp:AuthnRequest -r sp:Response
ZX_ROOTS+=-r sp:LogoutRequest -r sp:LogoutResponse
ZX_ROOTS+=-r sp:ManageNameIDRequest -r sp:ManageNameIDResponse
ZX_ROOTS+=-r e:Envelope -r e:Header -r e:Body

ZX_SG+=sg/saml-schema-metadata-2.0.sg
ZX_SG+=sg/shibboleth-metadata-1.0.sg
ZX_SG+=sg/sstc-saml-idp-discovery.sg
ZX_ROOTS+=-r md:EntityDescriptor -r md:EntitiesDescriptor

endif

# OASIS XACML 2.0 (and committee draft 1)

ifeq ($(ENA_XACML2),1)

ZX_SG += sg/access_control-xacml-2.0-context-schema-os.sg
ZX_SG += sg/access_control-xacml-2.0-policy-schema-os.sg
ZX_SG += sg/access_control-xacml-2.0-saml-assertion-schema-os.sg
ZX_SG += sg/access_control-xacml-2.0-saml-protocol-schema-os.sg
ZX_SG += sg/xacml-2.0-profile-saml2.0-v2-schema-protocol-cd-1.sg
ZX_SG += sg/xacml-2.0-profile-saml2.0-v2-schema-assertion-cd-1.sg
ZX_ROOTS += -r xasp:XACMLAuthzDecisionQuery -r xasp:XACMLPolicyQuery
ZX_ROOTS += -r xaspcd1:XACMLAuthzDecisionQuery -r xaspcd1:XACMLPolicyQuery

endif

# Liberty ID-WSF 2.0

ifeq ($(ENA_WSF2),1)

ZX_SG += sg/ws-addr-1.0.sg
ZX_SG += sg/wss-secext-1.0.sg sg/wss-util-1.0.sg
ZX_SG += sg/liberty-idwsf-soap-binding.sg sg/liberty-idwsf-soap-binding-v2.0.sg
ZX_SG += sg/liberty-idwsf-security-mechanisms-v2.0.sg sg/liberty-idwsf-disco-svc-v2.0.sg
ZX_SG += sg/liberty-idwsf-interaction-svc-v2.0.sg sg/liberty-idwsf-utility-v2.0.sg
ZX_SG += sg/id-dap.sg sg/liberty-idwsf-subs-v1.0.sg sg/liberty-idwsf-dst-v2.1.sg
ZX_SG += sg/liberty-idwsf-idmapping-svc-v2.0.sg sg/liberty-idwsf-people-service-v1.0.sg
ZX_SG += sg/liberty-idwsf-authn-svc-v2.0.sg sg/xml.sg sg/xsi.sg sg/xs.sg sg/id-mm7-R6-1-4.sg
ZX_SG += sg/lib-id-sis-cb-proto.sg sg/lib-id-sis-cb-cdm.sg sg/liberty-id-sis-gl-v1.0-14.sg
ZX_SG += sg/liberty-idwsf-dp-v1.0.sg sg/liberty-idwsf-idp-v1.0.sg
ZX_SG += sg/liberty-idwsf-pmm-v1.0.sg sg/liberty-idwsf-prov-v1.0.sg
ZX_SG += sg/liberty-idwsf-shps-v1.0.sg
ZX_SG += sg/hr-xml-sampo.sg sg/id-hrxml.sg
ZX_SG += sg/demo-media-v1.0.sg
ZX_ROOTS+= -r a:EndpointReference -r sec:Token
ZX_ROOTS+= -r hrxml:Candidate

#ZX_SG += sg/saml-schema-assertion-2.0.sg sg/saml-schema-protocol-2.0.sg sg/xmldsig-core.sg sg/xenc-schema.sg sg/saml-schema-metadata-2.0.sg sg/oasis-sstc-saml-schema-protocol-1.1.sg sg/oasis-sstc-saml-schema-assertion-1.1.sg sg/liberty-idff-protocols-schema-1.2-errata-v2.0.sg sg/liberty-authentication-context-v2.0.sg

endif

# SAML 1.1

ifeq ($(ENA_SAML11),1)

ZX_SG += sg/oasis-sstc-saml-schema-protocol-1.1.sg sg/oasis-sstc-saml-schema-assertion-1.1.sg
ZX_ROOTS += -r sa11:Assertion -r sp11:Request -r sp11:Response

endif

# Liberty ID-FF 1.2

ifeq ($(ENA_FF12),1)

ZX_SG += sg/liberty-idff-protocols-schema-1.2-errata-v2.0.sg sg/liberty-authentication-context-v2.0.sg
ZX_ROOTS+= -r ff12:Assertion -r ff12:AuthnRequest -r ff12:AuthnResponse
ZX_ROOTS+= -r ff12:AuthnRequestEnvelope -r ff12:AuthnResponseEnvelope
ZX_ROOTS+= -r ff12:RegisterNameIdentifierRequest -r ff12:RegisterNameIdentifierResponse
ZX_ROOTS+= -r ff12:FederationTerminationNotification
ZX_ROOTS+= -r ff12:LogoutRequest -r ff12:LogoutResponse
ZX_ROOTS+= -r ff12:NameIdentifierMappingRequest -r ff12:NameIdentifierMappingResponse
ZX_SG+=    sg/liberty-metadata-v2.0.sg
ZX_ROOTS+= -r m20:EntityDescriptor -r m20:EntitiesDescriptor

endif

# Liberty ID-WSF 1.1

ifeq ($(ENA_WSF11),1)

ZX_SG += sg/liberty-idwsf-soap-binding-v1.2.sg  sg/liberty-idwsf-security-mechanisms-v1.2.sg
ZX_SG += sg/liberty-idwsf-disco-svc-v1.2.sg     sg/liberty-idwsf-interaction-svc-v1.1.sg

endif

# WS-Trust

ifeq ($(ENA_WST),1)

ZX_SG += sg/ws-trust-1.3.sg sg/ws-policy.sg sg/ws-secureconversation-1.3.sg

endif

# TAS3

ifeq ($(ENA_TAS3),1)

ZX_SG += sg/tas3.sg sg/tas3sol.sg

endif

#
# Generated files (the zxid/c subdirectory) (see also Manifest if you add files)
#

ZX_GEN_GPERF=\
 c/zx-a.gperf    c/zx-di12.gperf  c/zx-lu.gperf    c/zx-xenc.gperf \
 c/zx-ac.gperf   c/zx-m20.gperf   c/zx-sec.gperf   c/zx-exca.gperf \
 c/zx-b.gperf    c/zx-ds.gperf    c/zx-md.gperf    c/zx-sec12.gperf \
 c/zx-b12.gperf  c/zx-e.gperf     c/zx-sp.gperf \
 c/zx-ff12.gperf c/zx-sa.gperf    c/zx-sp11.gperf \
 c/zx-is.gperf   c/zx-sa11.gperf  c/zx-wsse.gperf \
 c/zx-di.gperf   c/zx-is12.gperf  c/zx-sbf.gperf   c/zx-wsu.gperf \
 c/zx-ecp.gperf  c/zx-paos.gperf  c/zx-dap.gperf   c/zx-ps.gperf \
 c/zx-im.gperf   c/zx-as.gperf    c/zx-subs.gperf  c/zx-dst.gperf \
 c/zx-cb.gperf   c/zx-cdm.gperf   c/zx-gl.gperf    c/zx-mm7.gperf \
 c/zx-wst.gperf  c/zx-wsp.gperf   c/zx-wsc.gperf \
 c/zx-xa.gperf   c/zx-xac.gperf   c/zx-xasa.gperf  c/zx-xasp.gperf \
 c/zx-xasacd1.gperf               c/zx-xaspcd1.gperf \
 c/zx-dp.gperf   c/zx-pmm.gperf   c/zx-prov.gperf  c/zx-idp.gperf c/zx-shps.gperf \
 c/zx-demomed.gperf c/zx-hrxml.gperf c/zx-idhrxml.gperf \
 c/zx-tas3.gperf  c/zx-tas3sol.gperf c/zx-shibmd.gperf c/zx-idpdisc.gperf \
 c/zx-xml.gperf

ZX_GEN_H=\
 c/zx-a-data.h    c/zx-di12-data.h  c/zx-lu-data.h    c/zx-xenc-data.h \
 c/zx-ac-data.h   c/zx-m20-data.h   c/zx-sec-data.h   c/zx-exca-data.h \
 c/zx-b-data.h    c/zx-ds-data.h    c/zx-md-data.h    c/zx-sec12-data.h \
 c/zx-b12-data.h  c/zx-e-data.h     c/zx-ns.h         c/zx-sp-data.h \
 c/zx-ff12-data.h c/zx-sa-data.h    c/zx-sp11-data.h \
 c/zx-data.h      c/zx-is-data.h    c/zx-sa11-data.h  c/zx-wsse-data.h \
 c/zx-di-data.h   c/zx-is12-data.h  c/zx-sbf-data.h   c/zx-wsu-data.h \
 c/zx-ecp-data.h  c/zx-paos-data.h  c/zx-dap-data.h   c/zx-ps-data.h \
 c/zx-im-data.h   c/zx-as-data.h    c/zx-subs-data.h  c/zx-dst-data.h \
 c/zx-cb-data.h   c/zx-cdm-data.h   c/zx-gl-data.h    c/zx-mm7-data.h \
 c/zx-wst-data.h  c/zx-wsp-data.h   c/zx-wsc-data.h \
 c/zx-xa-data.h   c/zx-xac-data.h   c/zx-xasa-data.h  c/zx-xasp-data.h \
 c/zx-xasacd1-data.h  c/zx-xaspcd1-data.h \
 c/zx-dp-data.h   c/zx-pmm-data.h   c/zx-prov-data.h  c/zx-idp-data.h        c/zx-shps-data.h \
 c/zx-demomed-data.h c/zx-hrxml-data.h c/zx-idhrxml-data.h \
 c/zx-xsi-data.h  c/zx-xs-data.h    c/zx-xml-data.h \
 c/zx-tas3-data.h  c/zx-tas3sol-data.h c/zx-shibmd-data.h c/zx-idpdisc-data.h

ZX_GEN_GETPUT_C= \
 c/zx-is-getput.c \
 c/zx-di12-getput.c c/zx-sa11-getput.c c/zx-sp11-getput.c \
 c/zx-a-getput.c \
 c/zx-is12-getput.c \
 c/zx-sbf-getput.c  c/zx-wsse-getput.c \
 c/zx-ac-getput.c \
 c/zx-lu-getput.c \
 c/zx-ds-getput.c c/zx-wsu-getput.c \
 c/zx-b-getput.c c/zx-m20-getput.c \
 c/zx-e-getput.c c/zx-sec-getput.c   c/zx-xenc-getput.c \
 c/zx-b12-getput.c c/zx-ff12-aux.c    c/zx-md-getput.c   c/zx-sec12-enc.c \
 c/zx-sec12-getput.c \
 c/zx-ff12-getput.c \
 c/zx-getput.c \
 c/zx-di-getput.c c/zx-sa-getput.c   c/zx-sp-getput.c \
 c/zx-sp11-aux.c \
 c/zx-ecp-getput.c \
 c/zx-paos-getput.c \
 c/zx-dap-getput.c \
 c/zx-ps-getput.c \
 c/zx-im-getput.c \
 c/zx-as-getput.c \
 c/zx-subs-getput.c \
 c/zx-dst-getput.c \
 c/zx-cb-getput.c \
 c/zx-cdm-getput.c \
 c/zx-gl-getput.c \
 c/zx-mm7-getput.c \
 c/zx-wst-getput.c \
 c/zx-wsp-getput.c \
 c/zx-wsc-getput.c \
 c/zx-xa-getput.c \
 c/zx-xac-getput.c \
 c/zx-xasa-getput.c \
 c/zx-xasacd1-getput.c \
 c/zx-xasp-getput.c \
 c/zx-xaspcd1-getput.c \
 c/zx-dp-getput.c \
 c/zx-pmm-getput.c \
 c/zx-prov-getput.c \
 c/zx-idp-getput.c \
 c/zx-shps-getput.c \
 c/zx-exca-getput.c \
 c/zx-hrxml-getput.c \
 c/zx-idhrxml-getput.c \
 c/zx-demomed-getput.c \
 c/zx-xsi-getput.c \
 c/zx-xs-getput.c \
 c/zx-xml-getput.c \
 c/zx-tas3-getput.c \
 c/zx-tas3sol-getput.c \
 c/zx-shibmd-getput.c \
 c/zx-idpdisc-getput.c

ZX_GEN_AUX_C= \
 c/zx-a-aux.c      c/zx-is12-aux.c \
 c/zx-sbf-aux.c     c/zx-wsse-aux.c \
 c/zx-ac-aux.c     c/zx-lu-aux.c \
 c/zx-ds-aux.c     c/zx-wsu-aux.c \
 c/zx-aux.c        c/zx-b-aux.c       c/zx-m20-aux.c \
 c/zx-e-aux.c      c/zx-sec-aux.c     c/zx-xenc-aux.c \
 c/zx-b12-aux.c    c/zx-md-aux.c \
 c/zx-sec12-aux.c \
 c/zx-ff12-aux.c   c/zx-di-aux.c      c/zx-sa-aux.c      c/zx-sp-aux.c \
 c/zx-is-aux.c \
 c/zx-di12-aux.c   c/zx-sa11-aux.c    c/zx-sp11-aux.c \
 c/zx-ecp-aux.c    c/zx-paos-aux.c \
 c/zx-dap-aux.c    c/zx-ps-aux.c      c/zx-im-aux.c \
 c/zx-as-aux.c     c/zx-subs-aux.c    c/zx-dst-aux.c \
 c/zx-cb-aux.c     c/zx-cdm-aux.c     c/zx-gl-aux.c \
 c/zx-mm7-aux.c    c/zx-wst-aux.c     c/zx-wsp-aux.c \
 c/zx-wsc-aux.c    c/zx-xa-aux.c      c/zx-xac-aux.c \
 c/zx-xasa-aux.c   c/zx-xasacd1-aux.c c/zx-xasp-aux.c \
 c/zx-xaspcd1-aux.c c/zx-dp-aux.c     c/zx-pmm-aux.c \
 c/zx-prov-aux.c   c/zx-idp-aux.c     c/zx-shps-aux.c \
 c/zx-exca-aux.c   c/zx-hrxml-aux.c   c/zx-idhrxml-aux.c \
 c/zx-demomed-aux.c c/zx-xsi-aux.c    c/zx-xs-aux.c \
 c/zx-xml-aux.c     c/zx-tas3-aux.c   c/zx-tas3sol-aux.c \
 c/zx-shibmd-aux.c  c/zx-idpdisc-aux.c

ZX_GEN_C= \
 c/zx-di12-dec.c   c/zx-sa11-dec.c     c/zx-sp11-dec.c \
 c/zx-a-dec.c \
 c/zx-is12-dec.c   c/zx-sbf-dec.c     c/zx-wsse-dec.c \
 c/zx-ac-dec.c     c/zx-lu-dec.c \
 c/zx-ds-dec.c     c/zx-wsu-dec.c \
 c/zx-b-dec.c      c/zx-m20-dec.c \
 c/zx-e-dec.c      c/zx-sec-dec.c     c/zx-xenc-dec.c \
 c/zx-b12-dec.c    c/zx-md-dec.c      c/zx-sec12-dec.c \
 c/zx-dec.c        c/zx-ff12-dec.c \
 c/zx-di-dec.c     c/zx-sa-dec.c      c/zx-sp-dec.c \
 c/zx-is-dec.c     c/zx-ecp-dec.c     c/zx-paos-dec.c \
 c/zx-dap-dec.c    c/zx-ps-dec.c      c/zx-im-dec.c \
 c/zx-as-dec.c     c/zx-subs-dec.c    c/zx-dst-dec.c \
 c/zx-cb-dec.c     c/zx-cdm-dec.c     c/zx-gl-dec.c \
 c/zx-mm7-dec.c    c/zx-wst-dec.c     c/zx-wsp-dec.c \
 c/zx-wsc-dec.c    c/zx-xa-dec.c      c/zx-xac-dec.c \
 c/zx-xasa-dec.c   c/zx-xasacd1-dec.c c/zx-xasp-dec.c \
 c/zx-xaspcd1-dec.c c/zx-dp-dec.c     c/zx-pmm-dec.c \
 c/zx-prov-dec.c   c/zx-idp-dec.c     c/zx-shps-dec.c \
 c/zx-exca-dec.c   c/zx-hrxml-dec.c   c/zx-idhrxml-dec.c \
 c/zx-demomed-dec.c c/zx-xsi-dec.c    c/zx-xs-dec.c \
 c/zx-xml-dec.c    c/zx-tas3-dec.c    c/zx-tas3sol-dec.c \
 c/zx-shibmd-dec.c c/zx-idpdisc-dec.c

ifeq ($(ENA_GEN),1)

### Schema based code generation
### If this runs over and over again, check timestamps in sg/ directory, or make -d -p
# gperf mystery flags explanation (most of these should be set via directives in .gperf source)
#  -t  programmer supplied struct type
#  -T  prevent the struct type from leaking in output (it is properly available from zx.h)
#  -K  indicate key field name (when not "name")
#  -D  duplicates allowed
#  -C  constant (readonly) tables
#  -l  compare key lengths before strcmp, nul byte compatibility
#  -G  global static table (i.e. not hidden as function static variable)
#  -P  pic tables (starting with int) for faster dynamic linking
#  -W arg  Word array name
#  -N arg  Lookup function name

$(XSD2SG_PL):
	@ls $(XSD2SG_PL) || ( echo "You need to install xsd2sg.pl from Plaindoc distribution at http://zxid.org/plaindoc/pd.html. Not found $(XSD2SG)" && exit 2 )

c/zx-ns.gperf c/zx-attrs.gperf c/zx-elems.gperf $(ZX_GEN_C) $(ZX_GEN_H): $(ZX_SG) dec-templ.c enc-templ.c aux-templ.c getput-templ.c $(XSD2SG_PL)
	$(XSD2SG) -z zx -gen c/zx -p zx_ $(ZX_ROOTS) -S $(ZX_SG) >junk

c/zx-ns.c: c/zx-ns.gperf
	@which $(GPERF) || ( echo "You need to install gperf from ftp.gnu.org. Not found $(GPERF)" && exit 2 )
	$(GPERF) $< | $(PERL) ./sed-zxid.pl nss >$@

#c/%.c: c/%.gperf
#	@which $(GPERF) || ( echo "You need to install gperf from ftp.gnu.org. Not found $(GPERF)" && exit 2 )
#	$(GPERF) -l $< | $(PERL) ./sed-zxid.pl elems >$@

c/zx-attrs.c: c/zx-attrs.gperf
	@which $(GPERF) || ( echo "You need to install gperf from ftp.gnu.org. Not found $(GPERF)" && exit 2 )
	$(GPERF) $< | $(PERL) ./sed-zxid.pl attrs >$@

c/zx-elems.c: c/zx-elems.gperf
	@which $(GPERF) || ( echo "You need to install gperf from ftp.gnu.org. Not found $(GPERF)" && exit 2 )
	$(GPERF) $< | $(PERL) ./sed-zxid.pl elems >$@

c/zx-const.h: c/zx-ns.c c/zx-attrs.c c/zx-elems.c
	$(PERL) ./gen-consts-from-gperf-output.pl zx_ $^ >$@

#	cat c/zx-ns.c | $(PERL) gen-consts-from-gperf-output.pl zx_ _NS zx_ns_tab >$@
#	cat c/zx-attrs.c | $(PERL) gen-consts-from-gperf-output.pl zx_ _ATTR zx_at_tab >>$@
#	cat c/zx-elems.c | $(PERL) gen-consts-from-gperf-output.pl zx_ _ELEM zx_el_tab >>$@

#c/zx-const.h: c/zx-attrs.c c/zx-ns.c
#	cat c/zx-attrs.c | $(PERL) gen-consts-from-gperf-output.pl zx_ _ATTR zx_at_tab >$@
#	cat c/zx-ns.c | $(PERL) gen-consts-from-gperf-output.pl zx_ _NS zx_ns_tab >>$@

# Other

# N.B. echo(1) command of some shells, such as dash, is broken such that the \n\ sequence
# is not preserved.

c/license.c: LICENSE-2.0.txt sed-zxid.pl
	$(PERL) ./sed-zxid.pl license <LICENSE-2.0.txt >$@

c/zxidvers.h: sed-zxid.pl
	$(PERL) ./sed-zxid.pl zxidvers $(ZXIDVERSION) $(ZXIDREL) <zxrev >$@

gen: c/zxidvers.h c/license.c c/zx-const.h c/zx-attrs.gperf

genwrap: gen zxidjava/zxid_wrap.c Net/SAML_wrap.c php/zxid_wrap.c py/zxid_wrap.c ruby/zxid_wrap.c csharp/zxid_wrap.c

# make cleany && make genwrap ENA_GEN=1 && make all ENA_GEN=1

endif

updatevers:
	rm -f c/zxidvers.h
	$(MAKE) c/zxidvers.h ENA_GEN=1

###
###  Perl Modules
###

# Main Net::SAML module - high level APIs

ifeq ($(ENA_GEN),1)

Net/SAML_wrap.c Net/SAML.pm: $(ZX_GEN_H) zxid.h zxid.i
	@which $(SWIG) || ( echo "You need to install swig-1.3.x from swig.org. Not found $(SWIG)" && exit 2 )
	$(SWIG) -o Net/SAML_wrap.c -perl zxid.i
	$(PERL) -pi -e 's/\*zxid_/*/i; s/\*SAML2?_/*/i' Net/SAML.pm

# Net::SAML::Metadata - low level metadata APIs

Metadata/Metadata_wrap.c Metadata/Metadata.pm: $(ZX_GEN_H) zxidmd.i
	@which $(SWIG) || ( echo "You need to install swig-1.3.x from swig.org. Not found $(SWIG)" && exit 2 )
	$(SWIG) -o Metadata/Metadata_wrap.c -perl zxidmd.i
	$(PERL) -pi -e 's/\*SAML2?_/*/i' Metadata/Metadata.pm

# Net::SAML::Raw - low level assertion and protocol APIs

Raw/Raw_wrap.c Raw/Raw.pm: $(ZX_GEN_H) zxidraw.i
	@which $(SWIG) || ( echo "You need to install swig-1.3.x from swig.org. Not found $(SWIG)" && exit 2 )
	$(SWIG) -o Raw/Raw_wrap.c -perl zxidraw.i
	$(PERL) -pi -e 's/\*SAML2?_/*/i' Raw/Raw.pm

# Net::WSF::WSC - high level APIs for implementing WSC

WSC/WSC_wrap.c WSC/WSC.pm: $(ZX_GEN_H) zxwsc.h wsc.i
	@which $(SWIG) || ( echo "You need to install swig-1.3.x from swig.org. Not found $(SWIG)" && exit 2 )
	$(SWIG) -o WSC/WSC_wrap.c -perl wsc.i
	$(PERL) -pi -e 's/\*zxwsc_/*/i; s/\*SAML2?_/*/i' WSC/WSC.pm

# Net::WSF::Raw - low level protocol APIs

WSF_Raw/Raw_wrap.c WSF_Raw/Raw.pm: $(ZX_GEN_H) wsfraw.i
	@which $(SWIG) || ( echo "You need to install swig-1.3.x from swig.org. Not found $(SWIG)" && exit 2 )
	$(SWIG) -o WSF_Raw/Raw_wrap.c -perl wsfraw.i
	$(PERL) -pi -e 's/\*zxwsc_/*/i; s/\*SAML2?_/*/i' WSF_Raw/Raw.pm

endif

# Overall

samlmod Net/Makefile: Net/SAML_wrap.c Net/SAML.pm $(LIBZXID_A)
	cd Net; $(PERL) Makefile.PL && $(MAKE)

samlmod_install: Net/Makefile
	cd Net; $(MAKE) install

samlmod_install_adhoc: Net/Makefile
	mkdir -p /usr/local/lib/site_perl/Net/
	mkdir -p /usr/local/lib/site_perl/auto/Net/SAML/
	cp Net/SAML.pm /usr/local/lib/site_perl/Net/ 
	cp Net/blib/arch/auto/Net/SAML/SAML.bs /usr/local/lib/site_perl/auto/Net/SAML/
	cp Net/blib/arch/auto/Net/SAML/SAML.so /usr/local/lib/site_perl/auto/Net/SAML/

mdmod: Metadata/Metadata_wrap.c Metadata/Metadata.pm
	cd Metadata; $(PERL) Makefile.PL && $(MAKE)

rawmod: Raw/Raw.pm Raw/Raw_wrap.c
	cd Raw; $(PERL) Makefile.PL && $(MAKE)

wscmod: WSC/WSC.pm WSC/WSC_wrap.c
	cd WSC; $(PERL) Makefile.PL && $(MAKE)

wsfrawmod: WSF_Raw/Raw.pm WSF_Raw/Raw_wrap.c
	cd WSF_Raw; $(PERL) Makefile.PL && $(MAKE)

ifeq ($(TARGET),xmingw64)

Net/SAML_wrap.$(OBJ_EXT): Net/SAML_wrap.c
	$(warning SAMLWRAP)
	$(CC) -c $(OUTOPT)$@ $(CFLAGS) $(CDEF) $(CINC) $<

endif

perlmod: samlmod

perlzxid: samlmod

perlzxid_install: samlmod_install

perlclean:
	@$(ECHO) ------------------ Making perlclean
	rm -rf Net/blib Net/*~ Net/*.o Net/Makefile Net/Makefile.old Net/SAML.bs
	rm -rf Metadata/blib Metadata/*~ Metadata/*.o Metadata/Makefile Metadata/Makefile.old Metadata/Metadata.bs
	rm -rf Raw/blib Raw/*~ Raw/*.o Raw/Makefile Raw/Makefile.old Raw/Raw.bs
	rm -rf WSC/blib WSC/*~ WSC/*.o WSC/Makefile WSC/Makefile.old WSC/WSC.bs
	rm -rf WSF_Raw/blib WSF_Raw/*~ WSF_Raw/*.o WSF_Raw/Makefile WSF_Raw/Makefile.old WSF_Raw/Raw.bs

perlcleaner: perlclean
	@$(ECHO) ------------------ Making perlcleaner
	rm -f Net/SAML.pm Net/SAML_wrap.c
	rm -f Metadata/Metadata_wrap.c Metadata/Metadata.pm
	rm -f Raw/Raw.pm Raw/Raw_wrap.c
	rm -f WSC/WSC.pm WSC/WSC_wrap.c
	rm -f WSF_Raw/Raw.pm WSF_Raw/Raw_wrap.c

###
###  PHP Module
###

ifeq ($(ENA_GEN),1)

php/zxid_wrap.c php/zxid.php php/php_zxid.h php/Makefile: $(ZX_GEN_H) zxid.h phpzxid.i
	@which $(SWIG) || ( echo "You need to install swig-1.3.x from swig.org. Not found $(SWIG)" && exit 2 )
	cd php; $(SWIG) -o zxid_wrap.c -noproxy -php ../phpzxid.i

endif

# -Wno-unused-label

php/zxid_wrap.$(OBJ_EXT): php/zxid_wrap.c
	$(warning PHPWRAP)
	$(CC) -c $(OUTOPT)$@ `$(PHP_CONFIG) --includes` $(CFLAGS) $(CDEF) $(CINC) $<

php/php_zxid$(SO): php/zxid_wrap.$(OBJ_EXT) $(LIBZXID_A)
	$(warning PHPLINK)
	$(LD) $(LDFLAGS) $(OUTOPT)php/php_zxid$(SO) -shared php/zxid_wrap.$(OBJ_EXT) $(LIBZXID) $(LIBS)

phpzxid: php/php_zxid$(SO)

phpzxid_install: php/php_zxid$(SO)
	@$(ECHO) Installing in `$(PHP_CONFIG) --extension-dir`
	mkdir -p `$(PHP_CONFIG) --extension-dir`
	$(CP) $< `$(PHP_CONFIG) --extension-dir`

#cp zxid.ini `$(PHP_CONFIG) --extension-dir`

phpclean:
	rm -rf php/*.$(OBJ_EXT) php/*~ php/*$(SO)

phpcleaner: phpclean
	rm -rf php/php_zxid.h php/zxid.php php/zxid_wrap.c

###
###  Python Module (*** Never tested)
###

ifeq ($(ENA_GEN),1)

py/zxid_wrap.c py/zxid.py py/Makefile: $(ZX_GEN_H) zxid.h pyzxid.i
	@which $(SWIG) || ( echo "You need to install swig-1.3.x from swig.org. Not found $(SWIG)" && exit 2 )
	cd py; $(SWIG) -o zxid_wrap.c -python ../pyzxid.i

endif

py/zxid_wrap.$(OBJ_EXT): py/zxid_wrap.c
	$(CC) -c $(OUTOPT)$@ `$(PY_CONFIG) --includes` $(CFLAGS) $(CDEF) $(CINC) $<

py/py_zxid$(SO): py/zxid_wrap.$(OBJ_EXT) $(LIBZXID_A)
	$(LD) $(LDFLAGS) $(OUTOPT)py/py_zxid$(SO) -shared py/zxid_wrap.$(OBJ_EXT) $(LIBZXID) $(LIBS)

pyzxid: py/py_zxid$(SO)

pyzxid_install: py/py_zxid$(SO)
	@$(ECHO) Installing in `$(PY_CONFIG) --extension-dir`
	mkdir -p `$(PY_CONFIG) --extension-dir`
	$(CP) $< `$(PY_CONFIG) --extension-dir`

pyclean:
	rm -rf py/*.$(OBJ_EXT) py/*~ py/*$(SO)

pycleaner: pyclean
	rm -rf py/zxid.py py/zxid_wrap.c

###
###  Ruby Module (*** Never tested)
###

ifeq ($(ENA_GEN),1)

ruby/zxid_wrap.c ruby/zxid.ruby ruby/Makefile: $(ZX_GEN_H) zxid.h rubyzxid.i
	@which $(SWIG) || ( echo "You need to install swig-1.3.x from swig.org. Not found $(SWIG)" && exit 2 )
	cd ruby; $(SWIG) -o zxid_wrap.c -ruby ../rubyzxid.i

endif

ruby/zxid_wrap.$(OBJ_EXT): ruby/zxid_wrap.c
	$(CC) -c $(OUTOPT)$@ `$(RUBY_CONFIG) --includes` $(CFLAGS) $(CDEF) $(CINC) $<

ruby/ruby_zxid$(SO): ruby/zxid_wrap.$(OBJ_EXT) $(LIBZXID_A)
	$(LD) $(LDFLAGS) $(OUTOPT)ruby/ruby_zxid$(SO) -shared ruby/zxid_wrap.$(OBJ_EXT) $(LIBZXID) $(LIBS)

rubyzxid: ruby/ruby_zxid$(SO)

rubyzxid_install: ruby/ruby_zxid$(SO)
	@$(ECHO) Installing in `$(RUBY_CONFIG) --extension-dir`
	mkdir -p `$(RUBY_CONFIG) --extension-dir`
	$(CP) $< `$(RUBY_CONFIG) --extension-dir`

rubyclean:
	rm -rf ruby/*.$(OBJ_EXT) ruby/*~ ruby/*$(SO)

rubycleaner: rubyclean
	rm -rf ruby/zxid.ruby ruby/zxid_wrap.c

###
###  C# (csharp) Module (*** Poorly tested)
###

ifeq ($(ENA_GEN),1)

csharp/zxid_wrap.c csharp/zxid.csharp csharp/Makefile: $(ZX_GEN_H) zxid.h csharpzxid.i
	@which $(SWIG) || ( echo "You need to install swig-1.3.x from swig.org. Not found $(SWIG)" && exit 2 )
	cd csharp; $(SWIG) -o zxid_wrap.c -noproxy -csharp ../csharpzxid.i

endif

csharp/zxid_wrap.$(OBJ_EXT): csharp/zxid_wrap.c
	$(CC) -c $(OUTOPT)$@ `$(CSHARP_CONFIG) --includes` $(CFLAGS) $(CDEF) $(CINC) $<

csharp/csharp_zxid$(SO): csharp/zxid_wrap.$(OBJ_EXT) $(LIBZXID_A)
	$(LD) $(LDFLAGS) $(OUTOPT)csharp/csharp_zxid$(SO) -shared csharp/zxid_wrap.$(OBJ_EXT) $(LIBZXID) $(LIBS)

csharpzxid: csharp/csharp_zxid$(SO)

csharpzxid_install: csharp/csharp_zxid$(SO)
	@$(ECHO) Installing in `$(CSHARP_CONFIG) --extension-dir`
	mkdir -p `$(CSHARP_CONFIG) --extension-dir`
	$(CP) $< `$(CSHARP_CONFIG) --extension-dir`

csharpclean:
	rm -rf csharp/*.$(OBJ_EXT) csharp/*~ csharp/*$(SO)

csharpcleaner: csharpclean
	rm -rf csharp/zxid.csharp csharp/zxid_wrap.c

###
###  Java JNI Module
###

ifeq ($(ENA_GEN),1)

zxidjava/zxid_wrap.c: $(ZX_GEN_H) zxid.h javazxid.i
	@which $(SWIG) || ( echo "You need to install swig-1.3.x from swig.org. Not found $(SWIG)" && exit 2 )
	cd zxidjava; $(SWIG) -noproxy -Dconst= -w451 -o zxid_wrap.c -java -package zxidjava ../javazxid.i
	$(PERL) -pi -e 's/SWIGTYPE_p_zxid_conf/zxid_conf/g' zxidjava/*.java
	mv zxidjava/SWIGTYPE_p_zxid_conf.java zxidjava/zxid_conf.java
	$(PERL) -pi -e 's/SWIGTYPE_p_zxid_ses/zxid_ses/g' zxidjava/*.java
	mv zxidjava/SWIGTYPE_p_zxid_ses.java zxidjava/zxid_ses.java
	$(PERL) -pi -e 's/SWIGTYPE_p_zxid_cgi/zxid_cgi/g' zxidjava/*.java
	mv zxidjava/SWIGTYPE_p_zxid_cgi.java zxidjava/zxid_cgi.java
	$(PERL) -pi -e 's/SWIGTYPE_p_zxid_entity_s/zxid_entity/g' zxidjava/*.java
	mv zxidjava/SWIGTYPE_p_zxid_entity_s.java zxidjava/zxid_entity.java
	$(PERL) -pi -e 's/SWIGTYPE_p_zx_sa_Assertion_s/zxid_a7n/g' zxidjava/*.java
	mv zxidjava/SWIGTYPE_p_zx_sa_Assertion_s.java zxidjava/zxid_a7n.java
	$(PERL) -pi -e 's/SWIGTYPE_p_zx_sa_NameID_s/zxid_nid/g' zxidjava/*.java
	mv zxidjava/SWIGTYPE_p_zx_sa_NameID_s.java zxidjava/zxid_nid.java
	$(PERL) -pi -e 's/SWIGTYPE_p_zx_a_EndpointReference_s/zxid_epr/g' zxidjava/*.java
	mv zxidjava/SWIGTYPE_p_zx_a_EndpointReference_s.java zxidjava/zxid_epr.java
	$(PERL) -pi -e 's/SWIGTYPE_p_zx_tas3_Status_s/zxid_tas3_status/g' zxidjava/*.java
	mv zxidjava/SWIGTYPE_p_zx_tas3_Status_s.java zxidjava/zxid_tas3_status.java
	$(PERL) -pi -e 's/SWIGTYPE_p_zx_e_Fault_s/zxid_fault/g' zxidjava/*.java
	mv zxidjava/SWIGTYPE_p_zx_e_Fault_s.java zxidjava/zxid_fault.java
	$(PERL) -pi -e 's/SWIGTYPE_p_zx_sec_Token_s/zxid_tok/g' zxidjava/*.java
	mv zxidjava/SWIGTYPE_p_zx_sec_Token_s.java zxidjava/zxid_tok.java
	$(PERL) -pi -e 's/(public static \w+ )zxid_/$$1/' zxidjava/zxidjni.java

endif

ifeq ($(TARGET),win32cl)
zxidjava/zxid_wrap.$(OBJ_EXT): zxidjava/zxid_wrap.c
	$(warning JAVAWRAP)
	$(CC) -c $< -Fozxid_wrap.obj $(JNI_INC) $(CFLAGS) $(CDEF) $(CINC)
	$(CP) zxid_wrap.obj $@
else
zxidjava/zxid_wrap.$(OBJ_EXT): zxidjava/zxid_wrap.c
	$(warning JAVAWRAP)
	$(CC) -c $< $(OUTOPT)$@ $(JNI_INC) $(CFLAGS) $(CDEF) $(CINC)
endif

$(ZXIDJNI_SO): zxidjava/zxid_wrap.$(OBJ_EXT) $(LIBZXID_A)
	$(warning JNILINK)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $(SHARED_FLAGS) $< $(SHARED_CLOSE) $(LIBZXID) $(SO_LIBS)

#link  -OUT:zxidjava/zxidjni.dll -DLL -LDd -MDd -shared --export-all-symbols zxidjava/zxid_wrap.obj zxid.lib -LIBPATH:&quot;G:/cvsdev/libcurl-7.19.3-win32-ssl-msvc/&quot;/lib/Debug -LIBPATH:&quot;C:/OpenSSL/&quot;/lib/VC -LIBPATH:&quot;C:/Program Files/GnuWin32/&quot;/lib curllib.lib libeay32MD.lib ssleay32MD.lib zlib.lib kernel32.lib user32.lib winmm.lib Ws2_32.lib -Wl,-no-whole-archive /SUBSYSTEM:WINDOWS /INCREMENTAL

zxidjava/zxidjni.class: zxidjava/zxidjni.java
	cd zxidjava; $(JAVAC) $(JAVAC_FLAGS) *.java

zxidjavatest.class: zxidjavatest.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) zxidjavatest.java

zxid.class: zxid.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) zxidjava/*.java zxid.java

zxidhlo.class: zxidhlo.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java zxidhlo.java

zxidsrvlet.class: zxidsrvlet.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java zxidsrvlet.java

app_demo.class: app_demo.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java app_demo.java

zxidappdemo.class: zxidappdemo.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java zxidappdemo.java

zxidwspdemo.class: zxidwspdemo.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java zxidwspdemo.java

zxidwspleaf.class: zxidwspleaf.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java zxidwspleaf.java

zxidwscprepdemo.class: zxidwscprepdemo.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java zxidwscprepdemo.java

ZxidSSOFilter.class: ZxidSSOFilter.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java ZxidSSOFilter.java

ZxidServlet.class: ZxidServlet.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java ZxidServlet.java

zxidjava.jar: zxidjava/zxidjni.class zxidjava/README.zxid-java
	$(CP) COPYING LICENSE-2.0.txt LICENSE.openssl LICENSE.ssleay LICENSE.curl zxidjava/
	$(JAR) cf zxidjava.jar zxidjava/*.class zxidjava/*.java zxidjava/COPYING zxidjava/LICENSE*

zxiddemo.war: zxidjava.jar
	mkdir -p zxidservlet/WEB-INF/classes/ #mkdir -p zxidservlet/WEB-INF/classes/zxidjava/
	$(CP) -f zxidjava.jar ./zxidservlet/WEB-INF/classes/
	$(CP) -f ./servlet/WEB-INF/web.xml ./zxidservlet/WEB-INF/
	$(CP) -f zxidsrvlet.class zxidappdemo.class zxidwscprepdemo.class zxidwspdemo.class zxidwspleaf.class zxidhlo.class zxidservlet/WEB-INF/classes/
	cd ./zxidservlet ; $(JAR) cf ../zxiddemo.war *; cd ../
	rm -rf zxidservlet

javazxid: $(ZXIDJNI_SO) zxidjava/zxidjni.class zxidhlo.class zxidsrvlet.class zxidappdemo.class zxidwscprepdemo.class zxidwspdemo.class zxidwspleaf.class zxidjavatest.class zxidjava.jar zxiddemo.war

# ZxidSSOFilter.class ZxidServlet.class

javazxid_install: $(ZXIDJNI_SO)
	@$(ECHO) "javazxid_install: Work in Progress. See zxid-java.pd"

# from Brian, somewhat obsoleted by zxiddemo.war
javazxid_war:
	mkdir -p zxidservlet/WEB-INF/classes/zxidjava/
	$(CP) -f ./zxidjava/*.class ./zxidservlet/WEB-INF/classes/zxidjava/
	$(CP) -f ./servlet/WEB-INF/web.xml ./zxidservlet/WEB-INF/
	$(CP) -f zxidsrvlet.class zxidappdemo.class zxidwscprepdemo.class zxidwspdemo.class zxidwspleaf.class zxidhlo.class zxidservlet/WEB-INF/classes/
	cd ./zxidservlet ; $(JAR) cf ../zxidservlet.war *; cd ../
	rm -rf zxidservlet

#  rsync zxididp root@elsa:/var/zxid/webroot/apache-tomcat-5.5.20/webapps
#  mv zxidservlet.war $(WEBAPPS_PATH)/

javaswigchk:
	ls zxidjava/SWIGTYPE*.java >foo
	fgrep zxidjava/SWIGTYPE Manifest | cmp - foo

gitreaddnoc:
	git add zxidjava/*.java zxidjava/*.c Net/Makefile Net/SAML.pm Net/*.c php/*.[hc]

gitreadd:
	git add zxidjava/*.java zxidjava/*.c Net/Makefile Net/SAML.pm Net/*.c php/*.[hc] c/*.[hc]

javaclean:
	rm -rf zxidjava/*.$(OBJ_EXT) zxidjava/*~ zxidjava/*$(SO) zxidjava/*.class *.class

javacleaner: javaclean
	rm -rf zxidjava/*.java zxidjava/zxid_wrap.c

benessosrvlet.class: benessosrvlet.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java benessosrvlet.java

benedemo.class: benedemo.java zxidjava/zxidjni.class
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(SERVLET_PATH) zxidjava/*.java benedemo.java

bene: benessosrvlet.class benedemo.class

###
### Apache authentication module
###

mod_auth_saml.$(OBJ_EXT): mod_auth_saml.c $(LIBZXID_A)
	$(warning MOD_AUTH_SAML COMPILE)
	$(CC) -o $@ -c $<  $(CFLAGS) $(CDEF) $(CINC) $(APACHE_INC) $(APR_INC)

mod_auth_saml$(SO): mod_auth_saml.$(OBJ_EXT) $(LIBZXID_A)
	$(warning MOD_AUTH_SAML LINK SO)
	$(LD) $(LDFLAGS) $(OUTOPT)mod_auth_saml$(SO) $(SHARED_FLAGS) mod_auth_saml.$(OBJ_EXT) $(SHARED_CLOSE) $(LIBZXID) $(MOD_AUTH_SAML_LIBS) $(LIBS)

precheck_apache:  precheck/chk-apache.$(OBJ_EXT) precheck/chk-apache
	precheck/chk-apache

apachezxid: precheck_apache precheck mod_auth_saml$(SO)

apachezxid_install: mod_auth_saml$(SO)
	$(CP) $< $(APACHE_MODULES)

mod_auth_saml: apachezxid
	@$(ECHO) "mod_auth_saml: not an official target. Use make apachezxid"

###
### mini_httpd with ZXID support. See also mini_httpd-1.19-zxid/Makefile
### for regular build without ZXID support.
### N.B. This is obsoleted by zxid_httpd, below.

MINI_HTTPD_DIR?=mini_httpd-1.19-zxid

$(MINI_HTTPD_DIR)/htpasswd: $(MINI_HTTPD_DIR)/htpasswd.$(OBJ_EXT)
	$(warning MINI_HTTPD COMPILE)
	$(LD) $(LDFLAGS) $(OUTOPT)$@$(EXE) $< $(LIBS)

$(MINI_HTTPD_DIR)/mini_httpd_zxid$(EXE): $(MINI_HTTPD_DIR)/mini_httpd.$(OBJ_EXT) $(MINI_HTTPD_DIR)/match.$(OBJ_EXT) $(MINI_HTTPD_DIR)/tdate_parse.$(OBJ_EXT) mini_httpd_filter.$(OBJ_EXT) $(LIBZXID_A)
	$(warning MINI_HTTPD LINK)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $^ $(LIBZXID) $(LIBS)

$(MINI_HTTPD_DIR)/mime_encodings.h: $(MINI_HTTPD_DIR)/mime_encodings.txt
	rm -f $@
	sed < $^ > $@ \
	  -e 's/#.*//' -e 's/[ 	]*$$//' -e '/^$$/d' \
	  -e 's/[ 	][ 	]*/", 0, "/' -e 's/^/{ "/' -e 's/$$/", 0 },/'

$(MINI_HTTPD_DIR)/mime_types.h: $(MINI_HTTPD_DIR)/mime_types.txt
	rm -f $@
	sed < $^ > $@ \
	  -e 's/#.*//' -e 's/[ 	]*$$//' -e '/^$$/d' \
	  -e 's/[ 	][ 	]*/", 0, "/' -e 's/^/{ "/' -e 's/$$/", 0 },/'

mini_httpd_zxid: $(MINI_HTTPD_DIR)/mini_httpd_zxid $(MINI_HTTPD_DIR)/htpasswd

###
### zxid_httpd (derived from mini_httd).
###

zxid_httpd$(EXE): zxid_httpd.$(OBJ_EXT) tdate_parse.$(OBJ_EXT) mini_httpd_filter.$(OBJ_EXT) $(LIBZXID_A)
	$(warning ZXID_HTTPD LINK)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $^ $(LIBS)

###
### Binaries (most binaries are built by implicit rules)
###

#zxid$(EXE): zxid.$(OBJ_EXT) $(LIBZXID_A)

$(DEFAULT_EXE) $(ALL_EXE): $(LIBZXID_A)

zxcot-static-x64: zxcot.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@$(EXE) $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

zxdecode-static-x64: zxdecode.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@$(EXE) $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

zxpasswd-static-x64: zxpasswd.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@$(EXE) $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

# *** unresolved link problem with __gcov_fork, which is not found in 3.4.6 libgcov.a

zxcall-static-x64: zxcall.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@$(EXE) $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

zxumacall-static-x64: zxumacall.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@$(EXE) $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

zxidhlo-static-x64: zxidhlo.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@$(EXE) $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

zxididp-static$(EXE): zxididp.$(OBJ_EXT) $(LIBZXID_A)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $< -static $(LIBZXID) $(LIBS)

zxididp-semistatic$(EXE): zxididp.$(OBJ_EXT) $(LIBZXID_A)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $< -static $(LIBZXID) $(LIBS) -dynamic -lc

zxididp-static-x64: zxididp.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@ $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

#	diet gcc -o zxididp zxididp.o -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

zxbench-static-x64: zxbench.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@ $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

ifeq ($(TARGET),mingw)
zxencdectest:
	echo "Port this for mingw" > zxencdectest
endif

zxmqtest-zmq$(EXE): zxmqtest.$(OBJ_EXT) $(LIBZXID_A)
	$(LD) $(LDFLAGS) $(OUTOPT)$@$(EXE) $^ -lzmq $(LIBZXID) $(LIBS)

zxmqtest.$(OBJ_EXT): zxmqtest.c
	$(CC)  $(OUTOPT)$@ -c $^ $(CFLAGS) $(CDEF) $(CINC) -DOPENAMQ -I/apps/openamq/std/include

zxmqtest-amq$(EXE): zxmqtest.$(OBJ_EXT) $(LIBZXID_A)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $^ -L/apps/openamq/std/lib -lamq_wireapi -lamq_common -lsmt -lasl -lipr -licl -lpcre -laprutil -lapr -lcrypt -lm $(LIBZXID) $(LIBS)

zxlogview-static-x64: zxlogview.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@ $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

zxbustailf-static-x64: zxbustailf.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@ $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

zxbuslist-static-x64: zxbuslist.$(OBJ_EXT) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@ $< -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

zxbusd: $(ZXBUSD_OBJ) $(LIBZXID_A)
	$(CC) $(OUTOPT)$@ $^ $(LIBS)

zxbusd-static-x64: $(ZXBUSD_OBJ) $(LIBZXID_A)
	diet gcc $(OUTOPT)$@ $^ -static -L. -lzxid -pthread -lpthread -L$(DIET_ROOT)/lib -L$(DIET_ROOT)/ssl/lib-x86_64 -lcurl -lssl -lcrypto -lz

zxidhrxml: zxidhrxmlwsc zxidhrxmlwsp

###
### Libraries
###

ifeq ($(PULVER),1)

$(LIBZXID_A): $(ZX_OBJ) $(ZXID_LIB_OBJ)
	cat pulver/c_saml2_dec_c.deps      | xargs $(ARC) $(LIBZXID_A)
	cat pulver/c_saml2_enc_c.deps      | xargs $(ARC) $(LIBZXID_A)
	cat pulver/c_saml2_aux_c.deps      | xargs $(ARC) $(LIBZXID_A)
	cat pulver/c_saml2_getput_c.deps   | xargs $(ARC) $(LIBZXID_A)
	cat pulver/c_saml2md_dec_c.deps    | xargs $(ARC) $(LIBZXID_A)
	cat pulver/c_saml2md_enc_c.deps    | xargs $(ARC) $(LIBZXID_A)
	cat pulver/c_saml2md_aux_c.deps    | xargs $(ARC) $(LIBZXID_A)
	cat pulver/c_saml2md_getput_c.deps | xargs $(ARC) $(LIBZXID_A)
	$(ARC) $(LIBZXID_A) $(ZXID_LIB_OBJ)

#	$(foreach fil,$^,$(shell $(ARC) $(LIBZXID_A) $(fil)))

else

ifeq ($(TARGET),win32cl)
$(LIBZXID_A): $(ZX_OBJ) $(ZX_GEN_C:.c=.obj) $(ZXID_LIB_OBJ) $(WSF_OBJ) $(OAUTH_OBJ) $(SMIME_LIB_OBJ)
	$(ARC) $(OUTOPT)zxid.lib $^
else
$(LIBZXID_A): $(ZX_OBJ) $(ZX_GEN_C:.c=.o) $(ZXID_LIB_OBJ) $(WSF_OBJ) $(OAUTH_OBJ) $(SMIME_LIB_OBJ)
	$(ARC) $(LIBZXID_A) $^
endif
endif

libzxid.so.0.0: $(LIBZXID_A)
	$(LD) $(OUTOPT)libzxid.so.0.0 $(SHARED_FLAGS) $^ $(SHARED_CLOSE) $(LIBS)

zxid.dll zxidimp.lib: $(LIBZXID_A)
	$(LD) $(OUTOPT)zxid.dll $(SHARED_FLAGS) -Wl,--output-def,zxid.def,--out-implib,zxidimp.lib $^ $(SHARED_CLOSE) $(SO_LIBS)

# -mdll

# N.B. Failing to supply -Wl,-no-whole-archive above will cause
# /apps/gcc/mingw/sysroot/lib/libmingw32.a(main.o):main.c:(.text+0x106): undefined reference to `WinMain@16'
# due to implicitly linked library libmingw32.a pulling in main. See also
# binutils ld info documentation (e.g. invocation/options specific to i386 PE
# targets).

###
### TAS3 Project Specific Targets
###

TAS3COMMONFILES=README.zxid-tas3 README.zxid Changes COPYING LICENSE-2.0.txt LICENSE.openssl LICENSE.ssleay LICENSE.curl Makefile zxmkdirs.sh

TAS3MAS=T3-SSO-ZXID-MODAUTHSAML_$(ZXIDREL)

tas3maspkg: mod_auth_saml$(SO)
	rm -rf $(TAS3MAS) $(TAS3MAS).zip
	mkdir $(TAS3MAS)
	$(PERL) ./sed-zxid.pl version $(ZXIDREL) < Manifest.T3-SSO-ZXID-MODAUTHSAML > $(TAS3MAS)/Manifest
	$(CP) mod_auth_saml$(SO) $(TAS3MAS)
	$(CP) $(TAS3COMMONFILES) $(TAS3MAS)
	zip -r $(TAS3MAS).zip $(TAS3MAS)

TAS3PHP=T3-SSO-ZXID-PHP_$(ZXIDREL)

tas3phppkg: php/php_zxid$(SO)
	rm -rf $(TAS3PHP) $(TAS3PHP).zip
	mkdir $(TAS3PHP)
	$(PERL) ./sed-zxid.pl version $(ZXIDREL) <Manifest.T3-SSO-ZXID-PHP >$(TAS3PHP)/Manifest
	$(CP) *.php php/php_zxid$(SO) php/zxid.php php/zxid.ini php/README.zxid-php zxid-php.pd $(TAS3PHP)
	$(CP) $(TAS3COMMONFILES) $(TAS3PHP)
	zip -r $(TAS3PHP).zip $(TAS3PHP)

TAS3JAVA=T3-SSO-ZXID-JAVA_$(ZXIDREL)

tas3javapkg: $(ZXIDJNI_SO) zxidjava/zxidjni.class
	rm -rf $(TAS3JAVA) $(TAS3JAVA).zip
	mkdir $(TAS3JAVA)
	mkdir $(TAS3JAVA)/zxidjava
	$(PERL) ./sed-zxid.pl version $(ZXIDREL) <Manifest.T3-SSO-ZXID-JAVA >$(TAS3JAVA)/Manifest
	$(CP) $(ZXIDJNI_SO) zxidjava/*.java zxidjava/*.class zxidjava/README.zxid-java zxid-java.pd $(TAS3JAVA)/zxidjava
	$(CP) $(TAS3COMMONFILES) $(TAS3JAVA)
	zip -r $(TAS3JAVA).zip $(TAS3JAVA)

TAS3IDP=T3-IDP-ZXID_$(ZXIDREL)

tas3idppkg: zxididp zxpasswd zxcot zxdecode
	rm -rf $(TAS3IDP) $(TAS3IDP).zip
	mkdir $(TAS3IDP)
	$(PERL) ./sed-zxid.pl version $(ZXIDREL) < Manifest.T3-IDP-ZXID > $(TAS3IDP)/Manifest
	$(CP) zxididp zxpasswd zxcot zxdecode zxid-idp.pd $(TAS3IDP)
	$(CP) $(TAS3COMMONFILES) $(TAS3IDP)
	zip -r $(TAS3IDP).zip $(TAS3IDP)

TAS3LINUXX86=T3-ZXID-LINUX-X86_$(ZXIDREL)

tas3linuxx86pkg: zxididp zxpasswd zxcot zxdecode zxlogview mod_auth_saml$(SO) php/php_zxid$(SO) $(ZXIDJNI_SO) zxidjava/zxidjni.class
	rm -rf $(TAS3LINUXX86) $(TAS3LINUXX86).zip
	mkdir $(TAS3LINUXX86)
	mkdir $(TAS3LINUXX86)/zxidjava
	mkdir $(TAS3LINUXX86)/php
	mkdir $(TAS3LINUXX86)/include
	mkdir $(TAS3LINUXX86)/include/zx
	mkdir $(TAS3LINUXX86)/include/zx/c
	$(PERL) ./sed-zxid.pl version $(ZXIDREL) < Manifest.T3-ZXID-LINUX-X86 > $(TAS3LINUXX86)/Manifest
	$(CP) mod_auth_saml$(SO) $(TAS3LINUXX86)
	$(CP) *.php zxid-php.pd $(TAS3LINUXX86)
	$(CP) php/php_zxid$(SO) php/zxid.php php/zxid.ini php/README.zxid-php $(TAS3LINUXX86)/php
	$(CP) zxididp zxpasswd zxcot zxdecode zxlogview zxid-idp.pd $(TAS3LINUXX86)
	$(CP) $(LIBZXID_A) $(TAS3LINUXX86)
	$(CP) $(ZXIDHDRS) $(TAS3LINUXX86)/include/zx
	$(CP) c/*.h $(TAS3LINUXX86)/include/zx/c
	$(CP) $(ZXIDJNI_SO) zxidjava/*.java zxidjava/*.class zxidjava/README.zxid-java zxid-java.pd $(TAS3LINUXX86)/zxidjava
	$(CP) $(TAS3COMMONFILES) $(TAS3LINUXX86)
	zip -r $(TAS3LINUXX86).zip $(TAS3LINUXX86)

TAS3WIN32=T3-ZXID-WIN32_$(ZXIDREL)

#tas3win32pkg: mod_auth_saml$(SO) php/php_zxid$(SO)
#	$(CP) mod_auth_saml$(SO) $(TAS3LINUXX86)
#	$(CP) *.php php/php_zxid.dll php/zxid.php php/zxid.ini php/README.zxid-php zxid-php.pd $(TAS3LINUXX86)

tas3win32pkg: zxid.dll zxididp zxpasswd zxcot zxdecode zxlogview $(ZXIDJNI_SO) zxidjava/zxidjni.class zxidappdemo.class zxidjava.jar zxiddemo.war
	rm -rf $(TAS3WIN32) $(TAS3WIN32).zip
	mkdir $(TAS3WIN32)
	mkdir $(TAS3WIN32)/include
	mkdir $(TAS3WIN32)/include/zx
	mkdir $(TAS3WIN32)/include/zx/c
	$(PERL) ./sed-zxid.pl version $(ZXIDREL) < Manifest.T3-ZXID-WIN32 > $(TAS3WIN32)/Manifest
	$(CP) zxid.dll zxid*.lib $(TAS3WIN32)/
	$(CP) $(ZXIDHDRS) $(TAS3WIN32)/include/zx
	$(CP) zxididp $(TAS3WIN32)/zxididp.exe
	$(CP) zxpasswd $(TAS3WIN32)/zxpasswd.exe
	$(CP) zxcot $(TAS3WIN32)/zxcot.exe
	$(CP) zxdecode $(TAS3WIN32)/zxdecode.exe
	$(CP) zxlogview $(TAS3WIN32)/zxlogview.exe
	$(CP) zxid-idp.pd $(TAS3WIN32)
	$(CP) mod_auth_saml.dll $(TAS3WIN32)
	$(CP) *.php php/php_zxid.dll php/zxid.php php/zxid.ini php/README.zxid-php zxid-php.pd $(TAS3WIN32)
	$(CP) $(ZXIDJNI_SO) $(TAS3WIN32)/
	$(CP) zxidjava.jar zxiddemo.war zxid-java.pd $(TAS3WIN32)
	$(CP) *.java *.class $(TAS3WIN32)
	$(CP) $(TAS3COMMONFILES) $(TAS3WIN32)
	zip -r $(TAS3WIN32).zip $(TAS3WIN32)

# Minimal package with mod_auth_saml or PHP
tas3win32pkg-mini: zxid.dll zxididp zxpasswd zxcot zxdecode zxlogview $(ZXIDJNI_SO) zxidjava/zxidjni.class zxidappdemo.class zxidjava.jar zxiddemo.war
	rm -rf $(TAS3WIN32) $(TAS3WIN32).zip
	mkdir $(TAS3WIN32)
	mkdir $(TAS3WIN32)/include
	mkdir $(TAS3WIN32)/include/zx
	mkdir $(TAS3WIN32)/include/zx/c
	$(PERL) ./sed-zxid.pl version $(ZXIDREL) < Manifest.T3-ZXID-WIN32 > $(TAS3WIN32)/Manifest
	$(CP) zxid.dll zxid*.lib $(TAS3WIN32)/
	$(CP) $(ZXIDHDRS) $(TAS3WIN32)/include/zx
	$(CP) zxididp $(TAS3WIN32)/zxididp.exe
	$(CP) zxpasswd $(TAS3WIN32)/zxpasswd.exe
	$(CP) zxcot $(TAS3WIN32)/zxcot.exe
	$(CP) zxdecode $(TAS3WIN32)/zxdecode.exe
	$(CP) zxlogview $(TAS3WIN32)/zxlogview.exe
	$(CP) zxid-idp.pd $(TAS3WIN32)
	$(CP) $(ZXIDJNI_SO) $(TAS3WIN32)/
	$(CP) zxidjava.jar zxiddemo.war zxid-java.pd $(TAS3WIN32)
	$(CP) *.java *.class $(TAS3WIN32)
	$(CP) $(TAS3COMMONFILES) $(TAS3WIN32)
	zip -r $(TAS3WIN32).zip $(TAS3WIN32)

TAS3SRC=T3-ZXID-SRC_$(ZXIDREL)

tas3srcpkg: zxid-$(ZXIDREL).tgz
	rm -rf $(TAS3SRC) $(TAS3SRC).zip
	mkdir $(TAS3SRC)
	$(PERL) ./sed-zxid.pl version $(ZXIDREL) < Manifest.T3-ZXID-SRC > $(TAS3SRC)/Manifest
	$(CP) zxid-$(ZXIDREL).tgz $(TAS3SRC)
	$(CP) README.zxid-tas3 Changes COPYING LICENSE-2.0.txt LICENSE.openssl LICENSE.ssleay LICENSE.curl $(TAS3SRC)
	zip -r $(TAS3SRC).zip $(TAS3SRC)

#tas3rel: tas3idppkg tas3javapkg tas3phppkg tas3maspkg tas3srcpkg
#tas3copyrel: tas3rel
#	scp $(TAS3SRC).zip $(TAS3IDP).zip $(TAS3JAVA).zip $(TAS3PHP).zip $(TAS3MAS).zip tas3repo:pool-in

tas3rel: tas3linuxx86pkg tas3srcpkg

# tas3pool T3-ZXID-SRC_0.54.zip && tas3pool -u T3-ZXID-SRC_0.54.zip
# tas3pool T3-ZXID-LINUX-X86_0.54.zip && tas3pool -u T3-ZXID-LINUX-X86_0.54.zip
# tas3pool T3-ZXID-WIN32_0.56.zip

tas3copyrel: tas3rel
	rsync $(TAS3SRC).zip $(TAS3LINUXX86).zip tas3repo:pool-in

.PHONY: precheck_prep_win precheck precheckclean tas3copyrel tas3rel tas3srcpkg
.PHONY: tas3win32pkg-mini tas3win32pkg tas3linuxx86pkg tas3idppkg tas3javapkg tas3phppkg tas3maspkg

###
### Precheck to help analyse compilation problems
###

ifeq (IGNORE,)
precheck/chk-zlib$(EXE): precheck/chk-zlib.$(OBJ_EXT)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $< $(LIBS)

precheck/chk-openssl$(EXE): precheck/chk-openssl.$(OBJ_EXT)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $< $(LIBS)

precheck/chk-curl$(EXE): precheck/chk-curl.$(OBJ_EXT)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $< $(LIBS)

else
endif

precheck/chk-apache.$(OBJ_EXT): precheck/chk-apache.c
	$(CC) $(OUTOPT)$@ -c $< $(CFLAGS) $(APACHE_INC) $(APR_INC)

precheck/chk-apache$(EXE): precheck/chk-apache.$(OBJ_EXT)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $< $(LIBS)

zxsizeof: zxsizeof.$(OBJ_EXT)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $< $(LIBZXID) $(LIBS)

zxsizeof-static-x64: zxsizeof.$(OBJ_EXT)
	diet gcc $(OUTOPT)$@$(EXE) zxsizeof.c -static

xzxsizeof:
	$(CC) $(OUTOPT)zxsizeof zxsizeof.o

zx/zx.h:
	echo "zx symlink for includes (ln -s . zx) missing. Emulating by creating zx directory..."
	mkdir zx
	mkdir zx/c
	$(CP) *.h zx
	$(CP) c/*.h zx/c

ifeq ($(CROSS_COMPILE),1)
precheck: precheck/chk-zlib.$(OBJ_EXT) precheck/chk-zlib$(EXE) precheck/chk-openssl.$(OBJ_EXT) precheck/chk-openssl$(EXE) precheck/chk-curl.$(OBJ_EXT) precheck/chk-curl$(EXE)
	@$(ECHO) "Cross compile simplified precheck ok."
	@$(ECHO)
else

# Windows does not support symlinks (or the support is confusing and buggy, especially
# when cygwin and/or mingw are involved): solution is to simply copy the headers.

precheck_prep_win:
	rm -rf zx
	mkdir zx zx/c
	$(CP) *.h zx/
	$(CP) c/*.h zx/c/

precheck: $(PRECHECK_PREP) precheck/chk-zlib.$(OBJ_EXT) precheck/chk-zlib$(EXE) precheck/chk-openssl.$(OBJ_EXT) precheck/chk-openssl$(EXE) precheck/chk-curl.$(OBJ_EXT) precheck/chk-curl$(EXE) zx/zx.h
	@$(ECHO) CC=$(CC)
	which gcc
	$(CC) -v
	@$(ECHO)
	precheck/chk-zlib$(EXE)
	precheck/chk-openssl$(EXE)
	precheck/chk-curl$(EXE)
	@$(ECHO) "Precheck ok."
	@$(ECHO)
endif

precheckclean:
	rm -f precheck/*.$(OBJ_EXT)
	rm -f precheck/chk-zlib.exe precheck/chk-openssl.exe precheck/chk-curl.exe precheck/chk-apache.exe

###
### Test suite (outdated, use zxcot -dirs instead)
###

t/cot:
	sh ./zxmkdirs.sh t/

t/idpcot:
	sh ./zxmkdirs.sh t/idp

t/wspcot:
	sh ./zxmkdirs.sh t/wsp

t/wsp2cot:
	sh ./zxmkdirs.sh t/wsp2

test: t/cot t/idpcot t/wsp t/wsp2 zxencdectest zxcall zxumacall zxididp
	$(PERL) zxtest.pl -a

#test: test.$(OBJ_EXT)
#	$(CC) $(OUTOPT)$@ $< $(LIBZXID) $(LIBS)

win32loadlibtest.exe: win32loadlibtest.$(OBJ_EXT)
	$(CC) $(OUTOPT)$@ $<

### Test dynamic link library loading (on Windows)

zxidjava/testjni.class: zxidjava/testjni.java
	cd zxidjava; $(JAVAC) $(JAVAC_FLAGS) test*.java

zxidjava/testjni.$(OBJ_EXT): zxidjava/testjni.c
	$(CC) -c $< $(OUTOPT)$@ $(JNI_INC) $(CFLAGS) $(CDEF) $(CINC)

zxidjava/libtestjni.a: zxidjava/testjni.$(OBJ_EXT)
	$(ARC) $@ $^

zxidjava/testjni.dll: zxidjava/libtestjni.a
	$(LD) $(OUTOPT)$@ $(SHARED_FLAGS) $^ $(SHARED_CLOSE)

zxidjava/testmain: zxidjava/testmain.$(OBJ_EXT)
	$(LD) $(LDFLAGS) $(OUTOPT)$@ $< $(LIBS)

testmain.class: testmain.java
	$(JAVAC) $(JAVAC_FLAGS) zxidjava/test*.java testmain.java

testdll: zxidjava/testmain zxidjava/testjni.dll testmain.class

testdll.zip: testdll
	zip $@ zxidjava/testmain zxidjava/testjni.dll testmain.class testmain.java zxidjava/test*.class zxidjava/test*.java

testdll.tar: testdll
	tar cf $@ zxidjava/testmain zxidjava/testjni.dll testmain.class testmain.java zxidjava/test*.class zxidjava/test*.java

testdllclean:
	rm -rf testmain.class zxidjava/test*.class zxidjava/test*.$(OBJ_EXT) zxidjava/testmain zxidjava/libtestjni.a zxidjava/test*.dll

testclean:
	rm -rf t/*ses t/*user t/*/uid t/*nid t/*log t/*cot t/*pem tmp/*.out tmp/*.err

###
### Installation (needs more work, try `make dir' or `make dir ZXID_PATH=/var/zxid/idp')
###  ./zxmkdirs.sh /var/zxid/idp
###

dir:
	sh ./zxmkdirs.sh $(ZXID_PATH)
	-cp default-cot/* $(ZXID_PATH)cot

#	cp zxid.pem $(ZXID_PATH)pem/sign-nopw-cert.pem
#	cp zxid.pem $(ZXID_PATH)pem/enc-nopw-cert.pem
#	cp zxid.pem $(ZXID_PATH)pem/logenc-nopw-cert.pem
#	cp zxid.pem $(ZXID_PATH)pem/logsign-nopw-cert.pem
#	cp zxid.pem $(ZXID_PATH)pem/logenc.key

dirs: dir
	@$(ECHO) "You should use `make dir' instead!"

install_nodep:
	@$(ECHO) "===== Installing in $(PREFIX) (to change do make install PREFIX=/your/path)"
	-mkdir -p $(PREFIX) $(PREFIX)/bin $(PREFIX)/lib $(PREFIX)/include/zxid $(PREFIX)/include/zx $(PREFIX)/doc
	$(CP) zxmkdirs.sh zxcall zxumacall zxpasswd zxcot zxlogview zxbusd zxbustailf zxbuslist zxdecode zxencdectest zxcleanlogs.sh zximport-htpasswd.pl zximport-ldif.pl xml-pretty.pl diffy.pl smime send.pl xacml2ldif.pl mockpdp.pl env.cgi zxid-java.sh zxidatsel.pl zxidnewuser.pl zxidcot.pl zxiddash.pl zxidexplo.pl zxidhlo zxidhlo.pl zxidhlo.php zxidhlo.sh zxidhlo-java.sh zxidhlocgi.php zxidhlowsf zxidhrxmlwsc zxidhrxmlwsp zxididp zxidsimple zxidwsctool zxidwspcgi zxtest.pl mini_httpd_zxid $(PREFIX)/bin
	$(CP) $(LIBZXID_A) libzxid.so* $(PREFIX)/lib
	$(CP) libzxid.so.0.0 $(PREFIX)/lib
	$(CP) *.h c/*.h $(PREFIX)/include/zxid
	$(CP) zx.h $(PREFIX)/include/zx
	$(CP) *.pd *.dia $(PREFIX)/doc
	@$(ECHO) "You will need to copy zxidhlo binary where your web server can find it and"
	@$(ECHO) "make sure your web server is configured to recognize zxidhlo as a CGI script."
	@$(ECHO)
	@$(ECHO) "For a quick test, you can try putting following in your /etc/hosts:"
	@$(ECHO)
	@$(ECHO) "  127.0.0.1       localhost sp1.zxidcommon.org sp1.zxidsp.org"
	@$(ECHO)
	@$(ECHO) "and then run"
	@$(ECHO)
	@$(ECHO) "  mini_httpd -p 8443 -c zxid -S -E zxid.pem"
	@$(ECHO)
	@$(ECHO) "in the zxid build (usually distribution) directory and then point web browser to"
	@$(ECHO)
	@$(ECHO) "https://sp1.zxidsp.org:8443/zxid"
	@$(ECHO)

install:  $(DEFAULT_EXE) $(LIBZXID_A) libzxid.so.0.0 dir install_nodep

.PHONY: dir dirs installtestclean testdllclean

#
# Maintenance
#

tags:
	etags *.[hc] c/*.[hc] mini_httpd-1.19-zxid/*.[hc]

#SSL=/aino/openssl-0.9.8g
#SSL=/aino/openssl-1.0.0c
SSL=/home/sampo/openssl-1.0.1m
BB=/aino/busybox-1.11.1
#DS=~/ds
#DS=/d/sampo/ds4/ds
DS=/home/sampo/ds
SLIM=/home/sampo/slim
PD=/home/sampo/pd
APACHE=/aino/httpd-2.2.8

megatags:
	etags *.[hc] c/*.[hc] c/*.ds  mini_httpd-1.19-zxid/*.[hc] $(SSL)/*/*.[hc] $(SSL)/*/*/*.[hc] $(PD)/xsd2sg.pl $(PD)/pd2tex $(BB)/*/*.[hc] $(BB)/*/*/*.[hc] $(BB)/*/*/*/*.[hc]

# $(DS)/*/*.[hc] $(DS)/*/*.ds $(DS)/io/dsproxy-test.pl $(SLIM)/*/*.ds $(SLIM)/conf/*/*.ds
# $(APACHE)/*/*.[hc] $(APACHE)/*/*/*.[hc] $(APACHE)/*/*/*/*.[hc] $(APACHE)/*/*/*/*/*.[hc] $(APACHE)/*/*/*/*/*/*.[hc]

docclean:
	rm -f *.dbx *.tex

distclean: clean

cleanbin:
	rm -f zxid zxidsimple zxbench zxencdectest zxmqtest $(LIBZXID_A) libzxid.so* zxsizeof zxid.stderr
	rm -f zxidhlo zxidhlowsf zxidhrxmlwsc zxidhrxmlwsp zxidsimple zxidsp zxidwsctool
	rm -f zxidwspcgi zxidxfoobarwsp zxpasswd zxcot zxcall zxumacall zxbusd zxbustailf zxbuslist
	rm -f mod_auth_saml$(SO) zxididp zxdecode zxlogview zxcot zxpasswd smime
	rm -f zxid.dll zxidjava/zxidjni.dll *.exe

miniclean: perlclean phpclean pyclean rubyclean csharpclean javaclean docclean precheckclean
	@$(ECHO) ------------------ Making miniclean
	rm -f *.o *.obj zxid zxlogview zxbench zxencdectest zxmqtest $(LIBZXID_A) libzxid.so* sizeof zxid.stderr
	rm -f zxidhlo zxidhlowsf zxidhrxmlwsc zxidhrxmlwsp zxidsimple zxidsp zxidwsctool
	rm -f mod_auth_saml$(SO) zxididp zxbusd zxbustailf zxbuslist
	rm -f core* *~ .*~ .\#* c/.*~ c/.\#* sg/*~ sg/.*~ sg/.\#* foo bar ak.*

# make cleany && make genwrap ENA_GEN=1 && make all ENA_GEN=1
# make cleany && make gen ENA_GEN=1 && make all ENA_GEN=1

cleany: clean perlcleaner phpcleaner pycleaner rubycleaner csharpcleaner javacleaner cleangcov
	@$(ECHO) ------------------ Making cleany
	rm -f c/*.[hc] c/*.gperf c/*.y c/*.ds
	rm -rf pulver; mkdir pulver

cleaner: cleany
	@$(ECHO) ================== Making cleaner
	rm -f deps deps.dep c/*.deps

regen: clean perlcleaner phpcleaner pycleaner rubycleaner csharpcleaner javacleaner
	@$(ECHO) ================== Making regen
	rm -f c/*.[hc] c/*.gperf c/*.y deps deps.dep c/*.deps

# N.B. The clean and dist targets deliberately do not delete contents of
#      directory c/ although they are generated files. This is to allow
#      zxid to be built without the tools needed to generate those files.
clean: perlclean phpclean pyclean rubyclean csharpclean javaclean docclean precheckclean cleanbin
	@$(ECHO) ------------------ Making clean
	rm -f *.o */*.o *.obj */*.obj
	rm -f core* *~ .*~ .\#* c/.*~ c/.\#* sg/*~ sg/.*~ sg/.\#* foo bar ak.*

winclean:
	del /Q precheck\*.obj precheck\*.exe
	del /Q *.obj c\*.obj

.PHONY: winclean clean regen cleaner cleany miniclean cleanbin distclean docclean megatags tags

strip_bins:
	$(ECHO) $(STRIP) $(DEFAULT_EXE) $(ALL_EXE)
	$(STRIP) $(DEFAULT_EXE) $(ALL_EXE)

# zxcot -n -g http://federation.njedge.net/metadata/njedge-fed-metadata.xml

dist zxid-$(ZXIDREL).tgz:
	rm -rf zxid-$(ZXIDREL)
	mkdir zxid-$(ZXIDREL) zxid-$(ZXIDREL)/c zxid-$(ZXIDREL)/sg zxid-$(ZXIDREL)/t zxid-$(ZXIDREL)/tex  zxid-$(ZXIDREL)/html zxid-$(ZXIDREL)/pulver zxid-$(ZXIDREL)/Net zxid-$(ZXIDREL)/Metadata zxid-$(ZXIDREL)/Raw zxid-$(ZXIDREL)/WSC zxid-$(ZXIDREL)/WSF_Raw zxid-$(ZXIDREL)/php zxid-$(ZXIDREL)/zxidjava zxid-$(ZXIDREL)/servlet zxid-$(ZXIDREL)/servlet/WEB-INF zxid-$(ZXIDREL)/servlet/META-INF zxid-$(ZXIDREL)/default-cot zxid-$(ZXIDREL)/py zxid-$(ZXIDREL)/ruby zxid-$(ZXIDREL)/csharp zxid-$(ZXIDREL)/precheck zxid-$(ZXIDREL)/pers zxid-$(ZXIDREL)/intra zxid-$(ZXIDREL)/protected zxid-$(ZXIDREL)/strong zxid-$(ZXIDREL)/other zxid-$(ZXIDREL)/mini_httpd-1.19-zxid  zxid-$(ZXIDREL)/mini_httpd-1.19-zxid/contrib  zxid-$(ZXIDREL)/mini_httpd-1.19-zxid/contrib/redhat-rpm zxid-$(ZXIDREL)/mini_httpd-1.19-zxid/scripts zxid-$(ZXIDREL)/drupal zxid-$(ZXIDREL)/drupal/authn_sso
	(cd zxid-$(ZXIDREL); ln -s . zx)
	$(PERL) mkdist.pl zxid-$(ZXIDREL) <Manifest
	tar czf zxid-$(ZXIDREL).tgz zxid-$(ZXIDREL)

linbindist:
	rm -rf zxid-$(ZXIDREL)-ix86-linux-bin
	mkdir zxid-$(ZXIDREL)-ix86-linux-bin zxid-$(ZXIDREL)-ix86-linux-bin/c zxid-$(ZXIDREL)-ix86-linux-bin/sg zxid-$(ZXIDREL)-ix86-linux-bin/t  zxid-$(ZXIDREL)-ix86-linux-bin/tex  zxid-$(ZXIDREL)-ix86-linux-bin/html zxid-$(ZXIDREL)-ix86-linux-bin/pulver zxid-$(ZXIDREL)-ix86-linux-bin/Net zxid-$(ZXIDREL)-ix86-linux-bin/Metadata zxid-$(ZXIDREL)-ix86-linux-bin/Raw zxid-$(ZXIDREL)-ix86-linux-bin/WSC zxid-$(ZXIDREL)-ix86-linux-bin/WSF_Raw zxid-$(ZXIDREL)-ix86-linux-bin/php zxid-$(ZXIDREL)-ix86-linux-bin/zxidjava zxid-$(ZXIDREL)-ix86-linux-bin/servlet zxid-$(ZXIDREL)-ix86-linux-bin/servlet/WEB-INF
	(cd zxid-$(ZXIDREL)-ix86-linux-bin; ln -s . zx)
	$(PERL) mkdist.pl zxid-$(ZXIDREL)-ix86-linux-bin <Manifest.bin
	tar czf zxid-$(ZXIDREL)-ix86-linux-bin.tgz zxid-$(ZXIDREL)-ix86-linux-bin

winbindist:
	rm -rf zxid-$(ZXIDREL)-win32-bin
	mkdir zxid-$(ZXIDREL)-win32-bin zxid-$(ZXIDREL)-win32-bin/c zxid-$(ZXIDREL)-win32-bin/zxidjava  zxid-$(ZXIDREL)-win32-bin/php
	$(CP) zxid.dll zxidhlo.exe zxidsimple.exe zxididp.exe zxcot.exe zxpasswd.exe zxdecode.exe zxlogview.exe smime.exe zxcall.exe zxumacall.exe *.a *.def *.h *.java *.class *.war zxid-$(ZXIDREL)-win32-bin
	$(CP) zxidjava/*.class $(ZXIDJNI_SO) zxidjava/zxid_wrap.c zxid-$(ZXIDREL)-win32-bin/zxidjava
	$(CP) COPYING LICENSE-2.0.txt LICENSE.openssl LICENSE.ssleay LICENSE.curl README.zxid README.zxid-win32 zxid-$(ZXIDREL)-win32-bin
	$(CP) c/*.h zxid-$(ZXIDREL)-win32-bin/c
	zip -r zxid-$(ZXIDREL)-win32-bin.zip zxid-$(ZXIDREL)-win32-bin

#	$(CP) *.php mod_auth_saml.dll zxid-$(ZXIDREL)-win32-bin
#	$(CP) php/*.php php/php_zxid.dll  zxid-$(ZXIDREL)-win32-bin/php


common_bins: zxlogview$(EXE)  zxcot$(EXE) zxdecode$(EXE) zxcall$(EXE) zxumacall$(EXE) smime$(EXE) zxidhlo$(EXE) zxidsimple$(EXE) zxididp$(EXE) zxpasswd$(EXE)


.PHONY: winbindist linbindist dist

# To create release
#   make cleaner          # remember c/zxidvers.h
#   time make dep ENA_GEN=1
#   time make all ENA_GEN=1
#   make doc
#     pd2tex README.zxid
#     pd2tex index.pd
#     pd2tex apache.pd
#     pd2tex mod_auth_saml.pd
#   make javaswigchk
#   make gitreadd
#   make dist
#   make copydist
#   make release
#   make relhtml
#   make clean
#   make TARGET=xmingw
#   make zxid.dll TARGET=xmingw
#   make winbindist
#   make winbinrel
#   make tas3rel
#   make tas3copyrel         # tas3pool -u T3-ZXID-LINUX-X86_0.54.zip
#    ./pool-submit.sh 0.62   # ssh kilo.tas3.eu
#   make gen ENA_GEN=1
# zxid.user@lists.unh.edu, wsf-dev@lists.openliberty.org

#WEBROOT=sampo@zxid.org:zxid.org
WEBROOTHOST=sampo@zxidp.org
WEBROOTDIR=/var/zxid/webroot
WEBROOT=sampo@zxidp.org:/var/zxid/webroot/zxid.org/

copydist:
	rsync zxid-$(ZXIDREL).tgz $(WEBROOT)

tex/%.pdf: %.pd
	$(PD2TEX) -noref -nortf -nodbx -nohtml $<

html/%.html: %.pd doc-inc.pd doc-end.pd
	$(PD2TEX) -noref -nortf -nodbx -notex $<

tex/README.zxid.pdf: README.zxid
	$(PD2TEX) -noref -nortf -nodbx -nohtml $<

html/README.zxid.html: README.zxid doc-inc.pd doc-end.pd
	$(PD2TEX) -noref -nortf -nodbx -notex README.zxid

DOC= html/README.zxid.html html/index.html html/apache.html html/mod_auth_saml.html html/zxid-simple.html html/zxid-install.html html/zxid-conf.html html/zxid-cot.html html/zxid-java.html html/zxid-log.html html/zxid-perl.html html/zxid-php.html html/zxid-raw.html html/zxid-wsf.html html/zxid-idp.html html/zxid-faq.html html/schemata.html

doc: $(DOC)

docpdf: $(DOC:html/%.html=tex/%.pdf)

cleandoc:
	rm -f $(DOC)

release:
	rsync tex/README.zxid.pdf html/README.zxid-win32.html html/i-*.png zxid-frame.html $(WEBROOT)

winbinrel:
	rsync zxid-$(ZXIDREL)-win32-bin.zip $(WEBROOT)

indexrel: zxid-tas3-ios-index.html old-releases.html
	rsync $^ $(WEBROOT)

reldoc:
	rsync $(DOC)  $(WEBROOT)/html

relhtml:
	rsync html/*  $(WEBROOT)/html

refhtml:
	rsync ref/html/*  $(WEBROOT)/ref/html

zxidpcopytc: html/zxidp-user-terms.html html/zxidp-sp-terms.html
	rsync html/zxidp-user-terms.html html/zxidp-sp-terms.html $(WEBROOT)/html

rsynclite:
	cd ..; rsync -a '--exclude=*.o' '--exclude=*.zip' '--exclude=TAGS' '--exclude=*.tgz' '--exclude=*.class' '--exclude=*.so' '--exclude=*.a'  '--exclude=zxlogview' '--exclude=zxidsimple'  '--exclude=zxidhlowsf'  '--exclude=zxidhlo' '--exclude=zxidsp' '--exclude=zxbusd' '--exclude=zxbustailf' '--exclude=zxbuslist' zxid mesozoic.homeip.net:

cvstag:
	cvs tag ZXID_ZXIDREL_$(ZXIDVERSION)

.PHONY: cvstag cleandoc docpdf doc copydist
.PHONY: rsyncline zxidpcopytc refhtml relhtml reldoc indexrel winbinrel release

### Coverage analysis
### See also: make gcov, make lcov (and lcovhtml directory), man gcov, man gprof
###   profiling:/home/sampo/zxid/zxidconf.gcda:Version mismatch - expected 304* got 403*
###
### N.B. Apparently gcov is very picky between compiler versions (and libgcov version).
### Be sure to use you only use matching pair. gcov is also fidgety about processing
### source code subdirectories (presumably because it was compiled from top level
### directory). Apparently all subdirectory .gcov files land on top level.
###
### .gcno graph files are created at compile time. Recompile (with  -ftest-coverage) to recreate.
### .gcda arc files are updated at runtime (if compiled with -fprofile-arcs)
### gmon.out is created at runtime if compiled with -pg
#
#ls *.c c/*.c Net/*.c php/*.c zxidjava/*.c precheck/*.c | xargs $(GCOV)
# 	$(GCOV) *.c c/*.c Net/*.c php/*.c zxidjava/*.c precheck/*.c
#	$(GCOV) -o Net Net/*.c
#	$(GCOV) -o php php/*.c

gcov:
	@$(ECHO) "Remember to compile for profiling: make all ENA_PG=1 && make gcov"
	echo GCOV=$(GCOV)
	which gcov
	$(GCOV) -v
	$(GCOV) *.c
	ls c/*.c | xargs -l $(GCOV) -o c
	$(GCOV) -o zxidjava zxidjava/*.c
	$(GCOV) -o precheck precheck/*.c

# gcov /a/d/sampo/zxid/zxidconf.gcda -o /home/sampo/zxid -b -c -a -p

covrep:
	sh ./covrep.sh

### lcov is alternative to gcov target (it runs gcove internally, as specified by --gcov-tool)
### We have tested with versions 1.8 and 1.9, see http://ltp.sourceforge.net/coverage/lcov.php

lcov:
	rm -rf lcovhtml; mkdir lcovhtml
	$(LCOV) --gcov-tool $(GCOV) --ignore-errors graph -b . -d . -c -no-checksum -o lcovhtml/zxid.info
	$(GENHTML) -t 'ZXID Code Coverage' -o lcovhtml lcovhtml/zxid.info

copylcov:
	ssh $(WEBROOTHOST) mkdir $(WEBROOTDIR)/lcovhtml-$(ZXIDREL) || true
	rsync -a lcovhtml/* $(WEBROOT)/lcovhtml-$(ZXIDREL)

gprof:
	gprof zxencdectest

cleangcov:
	rm -f *.gcno *.gcda *.c.gcov *.y.gcov *.c-ann gmon.out
	rm -f */*.gcno */*.gcda */*.c.gcov */*.y.gcov */*.c-ann */gmon.out
	rm -f lcovhtml/zxid.info lcovhtml/zxid/*.html lcovhtml/zxid/c/*.html
	rm -f gmon.out

.PHONY: cleangcov gprof copylcov lcov gcov covrep

### Call graphs and reference documentation

function.list: 
	$(PERL) ./call-anal.pl -n *.c >junk

callgraph_annotate: 
	$(PERL) ./call-anal.pl *.c >callgraph.dot

callgraph: 
	$(PERL) ./call-anal.pl -n *.c >callgraph.dot
	dot -Tps main-call.dot -o main-call.ps
	dot -Tps callgraph.dot -o callgraph.ps  # slow

callgraph_zxbus: 
	$(PERL) ./call-anal.pl -n *.c >callgraph.dot
	dot -Tps ref/hi_shuffle-call.dot       -o ref/hi_shuffle-call.ps
	dot -Tps ref/zxbus_listen_msg-call.dot -o ref/zxbus_listen_msg-call.ps
	dot -Tps ref/zxid_simple_cf-call.dot   -o ref/zxid_simple_cf-call.ps

API_REF_SRC=aux-templ.c dec-templ.c enc-templ.c getput-templ.c \
 mod_auth_saml.c \
 zxcrypto.c zxida7n.c zxidcdc.c zxidcgi.c zxidconf.c zxidcurl.c \
 zxidecp.c zxidepr.c zxidlib.c zxidloc.c \
 zxidmeta.c zxidmk.c zxidmkwsf.c zxidmni.c zxidpep.c zxidpdp.c \
 zxidses.c zxidsimp.c zxidpool.c zxidslo.c zxidspx.c zxididpx.c zxiddec.c \
 zxidsso.c zxidpsso.c zxiddi.c   zxidim.c  zxidps.c \
 zxiduser.c zxidwsc.c zxidwsp.c \
 zxlib.c zxlibdec.c zxlibenc.c zxbusprod.c zxlog.c zxlogview.c zxns.c zxpw.c zxsig.c zxutil.c

refcall:
	$(PERL) ./call-anal.pl -n $(API_REF_SRC) >callgraph.dot

reference: refcall
	cd ref; $(PD2TEX) -noref -nortf -nodbx ref.pd
	cd ref/tex; pdflatex -file-line-error-style -interaction=errorstopmode ref.tex # Thrice so refs and index are right
	cd ref/tex #; pdflatex -file-line-error-style -interaction=errorstopmode ref.tex # Thrice so refs and index are right

ifeq ($(PULVER),1)

dep: $(PULVER_DEPS)
	rm -f deps.dep
	$(MAKE) deps.dep

deps: zxdecode.c zxcot.c zxpasswd.c zxidhlo.c zxbusd.c zxbustailf.c zxbuslist.c zxidsimple.c $(ZX_OBJ:.o=.c) c/saml2-const.h c/saml2md-const.h c/wsf-const.h $(PULVER_DEPS) c/zxidvers.h
	@$(ECHO) ================== Making deps
	cat pulver/c_saml2_dec_c.deps | xargs $(CC) $(CDEF) $(CINC) -MM >>deps.dep
	cat pulver/c_saml2_enc_c.deps | xargs $(CC) $(CDEF) $(CINC) -MM >>deps.dep
	cat pulver/c_saml2_aux_c.deps | xargs $(CC) $(CDEF) $(CINC) -MM >>deps.dep
	cat pulver/c_saml2_getput_c.deps | xargs $(CC) $(CDEF) $(CINC) -MM >>deps.dep
	cat pulver/c_saml2md_dec_c.deps | xargs $(CC) $(CDEF) $(CINC) -MM >>deps.dep
	cat pulver/c_saml2md_enc_c.deps | xargs $(CC) $(CDEF) $(CINC) -MM >>deps.dep
	cat pulver/c_saml2md_aux_c.deps | xargs $(CC) $(CDEF) $(CINC) -MM >>deps.dep
	cat pulver/c_saml2md_getput_c.deps | xargs $(CC) $(CDEF) $(CINC) -MM >>deps.dep
	$(CC) $(CDEF) $(CINC) -MM zxdecode.c zxcot.c zxpasswd.c zxidhlo.c zxbusd.c zxbustailf.c zxbuslist.c zxidsimple.c c/saml2-const.h c/saml2md-const.h >>deps.dep

#	$(ECHO) Deps built. $(foreach fil,$^,$(shell $(fil) >>deps.dep))

else

dep: deps

deps: $(ZX_OBJ:.o=.c) $(ZXID_LIB_OBJ:.o=.c) $(WSF_OBJ:.o=.c) $(OAUTH_OBJ:.o=.c) $(SMIME_LIB_OBJ:.o=.c) zxdecode.c zxcot.c zxpasswd.c zxidhlo.c zxbusd.c zxbustailf.c zxbuslist.c zxidsp.c zxidsimple.c $(ZX_OBJ:.o=.c) $(ZX_GEN_H) $(ZX_GEN_C) c/zx-const.h c/zxidvers.h
	$(CC) $(CDEF) $(CINC) -MM $^ >deps.dep

# make gen ENA_GEN=1

endif

# N.B. If deps target and the actual deps.dep file have same name,
# the deps target will be made every time deps is missing - even
# when attempting to run `make clean'

-include deps.dep

seehelp:
	@$(ECHO) "If you get compilation errors, try: make help"
	@$(ECHO) "Now trying to compile series of test programs to check dependencies..."
	@$(ECHO)

help:
	@$(ECHO) "ZXID $(ZXIDREL) make help (see zxid.org for further information)"
	@$(ECHO)
	@$(ECHO) "N.B.  There is no configure script. The Makefile works for all"
	@$(ECHO) "      supported platforms by provision of correct TARGET option."
	@$(ECHO) "N.B2: We distribute some generated files. If they are missing, you need"
	@$(ECHO) "      to regenerate them: make cleaner; make dep ENA_GEN=1"
	@$(ECHO)
	@$(ECHO) "To compile for Linux 2.6: make or make TARGET=Linux"
	@$(ECHO) "To compile for MacOS 10:  make TARGET=macosx"
	@$(ECHO) "To compile for Solaris 8: make TARGET=sol8"
	@$(ECHO) "To compile for Sparc Solaris 8 with cross compiler:"
	@$(ECHO) '  PATH=/apps/gcc/sol8/bin:/apps/binutils/sol8/bin:$$PATH make TARGET=xsol8'
	@$(ECHO)
	@$(ECHO) "If you get compilation or linking errors about missing this or that,"
	@$(ECHO) "the chances are that you need to override some make variables with"
	@$(ECHO) "paths that make sense in your local situation. The best way is to"
	@$(ECHO) "first study the Makefile and then add your overrides to localconf.mk"
	@$(ECHO) "or on make command line. Some of the most common ones:"
	@$(ECHO) "  CFLAGS        Additional compiler flags needed on your platform"
	@$(ECHO) "  CDEF          Additional -D flags needed on your platform"
	@$(ECHO) "  CINC          Additional -I flags needed on your platform"
	@$(ECHO) "  LIBS          Additional -L and -l flags needed on your platform"
	@$(ECHO) "  JAVAC         Where to find javac; where jdk is installed"
	@$(ECHO) "  JNI_INC       Where jni.h and jni_md.h are found"
	@$(ECHO) "  SERVLET_PATH  Where servlet-api.jar is found; where Tomcat is installed."
	@$(ECHO) "  SHARED        Set to 1 for shared object (DLL) build. Default: static."
	@$(ECHO)
	@$(ECHO) "You may need to install dependency packages. For compilation you"
	@$(ECHO) "need the devel versions that have the headers. For example: "
	@$(ECHO) "  sudo apt-get install build-essential  # Debian"
	@$(ECHO) "  sudo apt-get install linux-libc-dev"
	@$(ECHO) "  sudo apt-get install libc6-dev-i386"
	@$(ECHO) "  sudo apt-get install libgcrypt-dev"
	@$(ECHO) "  sudo apt-get install libssl-dev"
	@$(ECHO) "  sudo apt-get install libcurl4-openssl-dev"
	@$(ECHO) "  sudo apt-get install libapr1-dev"
	@$(ECHO) "  sudo apt-get install apache2-dev"
	@$(ECHO) "  sudo apt-get install php5-dev"
	@$(ECHO) "  sudo apt-get install openjdk-6-jdk"
	@$(ECHO) "  sudo apt-get install mini-httpd"
	@$(ECHO) "  sudo yum -y install openssl-devel     # Redhat"
	@$(ECHO) "  sudo yum -y install libcurl-devel"
	@$(ECHO)
	@$(ECHO) "Following platform TARGETs are available:"
	@$(ECHO)
	@egrep '^ifeq \(.\(TARGET\),[A-Za-z0-9-]+\)' Makefile
	@$(ECHO)
	@$(ECHO) "Following make targets are available:"
	@$(ECHO)
	@egrep '^[a-z-]+:' Makefile

.PHONY: help seehelp dep deps reference refcall callgraph_zxbus callgraph callgraph_annotate

#EOF
