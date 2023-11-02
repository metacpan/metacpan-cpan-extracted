# This is a test GNUmakefile for Configure_win32()
# I need this to test all possible configuration stuff.
#
# $Id$
#
# These are not touched by default (Must be checked either way)
INST_DRV	:= C:
INST_TOP	:= $(INST_DRV)\perl
#
# These are commented out by default
INST_VER	:= \5.9.0
INST_ARCH	:= \$(ARCHNAME)

# The thread/fork() stuff. These are turned on by default,
# but for smoke purpuses, they will be turned off by default.
USE_MULTI	:= define
USE_ITHREADS	:= define
USE_IMP_SYS	:= define

# PERLIO, should *always* be 'define' (we don't do -U...)
USE_PERLIO	= define

# Additional compiler flags can be specified here.
#BUILDOPT	:= $(BUILDOPTEXTRA)

# Large File Support (files > 2Gb)
# Not touched by default
USE_LARGE_FILES	:= define

#BUILD_STATIC	:= define
#ALL_STATIC	:define

# CCTYPE has no visible default in Makefile
#CCTYPE		:= MSVC20
#CCTYPE		:= MSVC60
#CCTYPE		:= BORLAND
#CCTYPE		:= GCC

# Hacks for older/newer compiler versions
#USE_GCC_V3_2	:= define
#BCCOLD		:= define

# CFG is used to implement -DDEBUGGING
#CFG		:= Debug

# For those who like crypt() implemented in Perl
#CRYPT_SRC	:= fctypt.c
#CRYPT_LIB	:= fcript.lib

# PERL_MALLOC while it is documented, I'll support it
#PERL_MALLOC	:= define

# CCHOME is used to set CCINCDIR and CCLIBDIR
.ifeq ($(CCTYPE),"BORLAND")
CCHOME		:= c:\borland\bcc55
.else
.ifeq ($(CCTYPE)","GCC")
CCHOME		:= C:\MingW
.else
CCHOME		:= $(MSVCDIR)
.endif
.endif

# A new thing to build a 32bit perl on 64bit windows
#WIN64		:= undef

#USE_64_BIT_INT		:= define

#USE_LONG_DOUBLE	:= define

#USE_QUADMATH		:= define
#I_QUADMATH		:= define

# IS_WIN95 is self explanatory (not found in Makefile)
#IS_WIN95	:= define

# EMAIL is used to set -Dcf_email=xxx
#EMAIL		:= 

##################### CHANGE THESE ONLY IF YOU MUST #####################

INST_DRV	= untuched
# INST_DRV	= untuched

# There is this bit I'd like to manipulate
CFG_VARS	=				\
	"INST_DRV=$(INST_DRV)"			\
	"INST_TOP=$(INST_TOP:s/\/\\/)"		\
	"optimize=$(OPTIMIZE)"

some_target : will break arguments up like this \
		CCTYPE=$(CCTYPE) > somewhere

# This target is used to generate the new makefile (.\makefile.95) for Win95

.\makefile.95: .\makefile.mk
        $(MINIPERL) genmk95.pl makefile.mk $(MK2)

#--------------------- END Win95 SPECIFIC ---------------------

# a blank target for when builds don't need to do certain things
# this target added for Win95 port but used to keep the WinNT port able to
# use this file
__not_needed:
        $(NOOP)

