# This is a test Makefile for Configure_win32()
# I need this to test all possible configuration stuff.
#
# These are not touched by default (Must be checked either way)
INST_DRV	= C:
INST_TOP	= $(INST_DRV)\perl
#
# These are not touched by default, and commented out
#INST_VER	= \5.9.0
#INST_ARCH	= \$(ARCHNAME)

# The thread/fork() stuff. These are turned on by default,
# but for smoke purpuses, they will be turned off by default.
USE_MULTI	= define
USE_ITHREADS	= define
USE_IMP_SYS	= define

# PERLIO, should *always* be 'define' (we don't do -U...)
USE_PERLIO	= define

# Large File Support (files > 2Gb)
# Not touched by default
USE_LARGE_FILES	= define

# To be introduced: BUILD_STATIC as -Uuseshrplib
#BUILD_STATIC	= define
#ALL_STATIC	= define

# CCTYPE has no visible default in Makefile
#CCTYPE		= MSVC20
#CCTYPE		= MSVC60

# CFG is used to implement -DDEBUGGING
#CFG		= Debug

# For those who like crypt() implemented in Perl
#CRYPT_SRC	= fctypt.c
#CRYPT_LIB	= fcript.lib

# PERL_MALLOC while it is documented, I'll support it
#PERL_MALLOC	= define

# CCHOME is used to set CCINCDIR and CCLIBDIR
#CCHOME		= f:\msvc20
CCHOME		= $(MSVCDIR)

# Additional compiler flags can be specified here.
#
#BUILDOPT	= $(BUILDOPTEXTRA)

# A new thing to build a 32bit perl on 64bit windows
#WIN64		= undef

# EMAIL is used to set -Dcf_email=xxx
#EMAIL		= 

##################### CHANGE THESE ONLY IF YOU MUST #####################

INST_DRV	= untuched
# INST_DRV	= untuched

# There is this bit I'd like to manipulate
CFG_VARS	=				\
	"INST_DRV=$(INST_DRV)"			\
	"INST_TOP=$(INST_TOP)"			\
	"optimize=$(OPTIMIZE:"=\")"

some_target : will break arguments up like this \
		CCTYPE=$(CCTYPE) > somewhere
