# This Makefile is for the Tk::pTk extension to perl.
#
# It was generated automatically by MakeMaker version
# 7.62 (Revision: 76200) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: (q[BINARY_LOCATION=darwin-thread-multi-2level/Tk1.29-PPM.tar.gz])
#

#   MakeMaker Parameters:

#     BUILD_REQUIRES => {  }
#     CONFIGURE_REQUIRES => {  }
#     DEFINE => q[]
#     DIR => []
#     INC => q[-I/opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk -I/opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk -I. -Ibitmaps      -I/opt/local/include -I/opt/local/include/freetype2]
#     LINKTYPE => q[static]
#     NAME => q[Tk::pTk]
#     OBJECT => q[$(O_FILES)]
#     PREREQ_PM => {  }
#     SKIP => [q[distclean], q[dist], q[makeaperl], q[xs_o]]
#     TEST_REQUIRES => {  }
#     TYPEMAPS => [q[/opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/typemap]]
#     VERSION => q[1.29]
#     XS_VERSION => q[0.9]
#     clean => { FILES=>q[libpTk$(LIB_EXT) *.bak] }
#     macro => { TKDIR=>q[/opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk], WINARCH=>q[x] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /opt/local/lib/perl5/5.34/darwin-thread-multi-2level/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = /usr/bin/cc
CCCDLFLAGS =  
CCDLFLAGS =  
DLEXT = bundle
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = /usr/bin/cc
LDDLFLAGS =   -bundle -undefined dynamic_lookup -L/opt/local/lib -Wl,-headerpad_max_install_names   -fstack-protector-strong
LDFLAGS =   -L/opt/local/lib -Wl,-headerpad_max_install_names   -fstack-protector-strong
LIBC = 
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = darwin
OSVERS = 21.3.0
RANLIB = ranlib
SITELIBEXP = /opt/local/lib/perl5/site_perl/5.34
SITEARCHEXP = /opt/local/lib/perl5/site_perl/5.34/darwin-thread-multi-2level
SO = dylib
VENDORARCHEXP = /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level
VENDORLIBEXP = /opt/local/lib/perl5/vendor_perl/5.34


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = Tk::pTk
NAME_SYM = Tk_pTk
VERSION = 1.29
VERSION_MACRO = VERSION
VERSION_SYM = 1_29
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 0.9
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = ../blib/arch
INST_SCRIPT = ../blib/script
INST_BIN = ../blib/bin
INST_LIB = ../blib/lib
INST_MAN1DIR = ../blib/man1
INST_MAN3DIR = ../blib/man3
MAN1EXT = 1pm
MAN3EXT = 3pm
MAN1SECTION = 1
MAN3SECTION = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = /opt/local
SITEPREFIX = /opt/local
VENDORPREFIX = /opt/local
INSTALLPRIVLIB = /opt/local/lib/perl5/5.34
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /opt/local/lib/perl5/site_perl/5.34
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = /opt/local/lib/perl5/vendor_perl/5.34
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /opt/local/lib/perl5/5.34/darwin-thread-multi-2level
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /opt/local/lib/perl5/site_perl/5.34/darwin-thread-multi-2level
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = /opt/local/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = /opt/local/libexec/perl5.34/sitebin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = /opt/local/libexec/perl5.34
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = /opt/local/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = /opt/local/libexec/perl5.34/sitebin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = /opt/local/libexec/perl5.34
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = /opt/local/share/man/man1p
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = /opt/local/share/perl5.34/siteman/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = /opt/local/share/perl5.34/man/man1
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = /opt/local/share/man/man3p
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = /opt/local/share/perl5.34/siteman/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = /opt/local/share/perl5.34/man/man3
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = /opt/local/lib/perl5/5.34
PERL_ARCHLIB = /opt/local/lib/perl5/5.34/darwin-thread-multi-2level
PERL_ARCHLIBDEP = /opt/local/lib/perl5/5.34/darwin-thread-multi-2level
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /opt/local/lib/perl5/5.34/darwin-thread-multi-2level/CORE
PERL_INCDEP = /opt/local/lib/perl5/5.34/darwin-thread-multi-2level/CORE
PERL = "/opt/local/bin/perl5.34"
FULLPERL = "/opt/local/bin/perl5.34"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /opt/local/lib/perl5/5.34/ExtUtils/MakeMaker.pm
MM_VERSION  = 7.62
MM_REVISION = 76200

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = Tk/pTk
BASEEXT = pTk
PARENT_NAME = Tk
DLBASE = $(BASEEXT)
VERSION_FROM = 
INC = -I/opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk -I/opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk -I. -Ibitmaps      -I/opt/local/include -I/opt/local/include/freetype2
DEFINE = 
OBJECT = $(O_FILES)
LDFROM = $(OBJECT)
LINKTYPE = static
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = tkTable.c \
	tkTableCell.c \
	tkTableCellSort.c \
	tkTableCmds.c \
	tkTableEdit.c \
	tkTableTag.c \
	tkTableUtil.c \
	tkTableWin.c
O_FILES  = tkTable.o \
	tkTableCell.o \
	tkTableCellSort.o \
	tkTableCmds.o \
	tkTableEdit.o \
	tkTableTag.o \
	tkTableUtil.o \
	tkTableWin.o
H_FILES  = mm.h \
	tkTable.h \
	tkTableversion.h \
	version.h
MAN1PODS = 
MAN3PODS = 

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIBDEP)$(DFSEP)Config.pm $(PERL_INCDEP)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)/Tk
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/Tk

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = $(INST_ARCHAUTODIR)/$(BASEEXT)$(LIB_EXT)
INST_DYNAMIC     = $(INST_ARCHAUTODIR)/$(DLBASE).$(DLEXT)
INST_BOOT        = $(INST_ARCHAUTODIR)/$(BASEEXT).bs

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVEDEP    = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = mm.h \
	tkTable.h \
	tkTableversion.h \
	version.h

GCCOPT =  -Wall -Wno-implicit-int -Wno-comment -Wno-unused -D__USE_FIXED_PROTOTYPES__


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 7.62
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:

XSUBPPDIR = /opt/local/lib/perl5/5.34/ExtUtils
XSUBPP = "$(XSUBPPDIR)$(DFSEP)xsubpp"
XSUBPPRUN = $(PERLRUN) $(XSUBPP)
XSPROTOARG = 
XSUBPPDEPS = /opt/local/lib/perl5/5.34/ExtUtils/typemap /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/typemap /opt/local/lib/perl5/5.34/ExtUtils$(DFSEP)xsubpp
XSUBPPARGS = -typemap '/opt/local/lib/perl5/5.34/ExtUtils/typemap' -typemap '/opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/typemap'
XSUBPP_EXTRA_ARGS =


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --
CP_NONEMPTY = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'cp_nonempty' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section skipped.

# --- MakeMaker macro section:
TKDIR = /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk
WINARCH = x


# --- MakeMaker depend section:


# --- MakeMaker cflags section:

CCFLAGS = -fno-common -DPERL_DARWIN -pipe -Os -fno-strict-aliasing -fstack-protector-strong -I/opt/local/include -DPERL_USE_SAFE_PUTENV
OPTIMIZE = -O3
PERLTYPE = 


# --- MakeMaker const_loadlibs section:

# Tk::pTk might depend on some other libraries:
# See ExtUtils::Liblist for details
#


# --- MakeMaker const_cccmd section:
CCCMD = $(CC) -c $(PASTHRU_INC) $(INC) \
	$(CCFLAGS) $(OPTIMIZE) \
	$(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION) \
	$(XS_DEFINE_VERSION)

# --- MakeMaker post_constants section:

INST_STATIC=libpTk$(LIB_EXT)


# --- MakeMaker pasthru section:
#Tk::MMutil pasthru

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	OPTIMIZE="$(OPTIMIZE)"\
	PREFIX="$(PREFIX)"\
	PASTHRU_DEFINE=' $(PASTHRU_DEFINE)'\
	PASTHRU_INC='-I/opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk -I/opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk -I. -Ibitmaps      -I/opt/local/include -I/opt/local/include/freetype2 $(PASTHRU_INC)'


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir pure_all subdirs clean_subdirs makemakerdflt manifypods realclean_subdirs subdirs_dynamic subdirs_pure_nolink subdirs_static subdirs-test_dynamic subdirs-test_static test_dynamic test_static



# --- MakeMaker c_o section:

.c.i:
	/usr/bin/cc  -I/opt/local/include  -E -c $(PASTHRU_INC) $(INC) \
	$(CCFLAGS) $(OPTIMIZE) \
	$(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION) \
	$(XS_DEFINE_VERSION) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(GCCOPT) $*.c > $*.i

.c.s :
	$(CCCMD) -S $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(GCCOPT) $*.c 

.c$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(GCCOPT) $*.c

.cpp$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(GCCOPT) $*.cpp

.cxx$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(GCCOPT) $*.cxx

.cc$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(GCCOPT) $*.cc

.C$(OBJ_EXT) :
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $(GCCOPT) $*.C


# --- MakeMaker xs_c section:



# --- MakeMaker xs_o section skipped.

# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

# Explicit dependencies provided
# $(O_FILES) : $(H_FILES)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: static
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic_bs section:
BOOTSTRAP = $(BASEEXT).bs

# As Mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BASEEXT).bs : $(FIRST_MAKEFILE) $(BOOTDEP)
	$(NOECHO) $(ECHO) "Running Mkbootstrap for $(BASEEXT) ($(BSLOADLIBS))"
	$(NOECHO) $(PERLRUN) \
		"-MExtUtils::Mkbootstrap" \
		-e "Mkbootstrap('$(BASEEXT)','$(BSLOADLIBS)');"
	$(NOECHO) $(TOUCH) "$(BASEEXT).bs"
	$(CHMOD) $(PERM_RW) "$(BASEEXT).bs"

$(INST_ARCHAUTODIR)/$(BASEEXT).bs : $(BASEEXT).bs $(INST_ARCHAUTODIR)$(DFSEP).exists
	$(NOECHO) $(RM_RF) $(INST_ARCHAUTODIR)/$(BASEEXT).bs
	- $(CP_NONEMPTY) $(BASEEXT).bs $(INST_ARCHAUTODIR)/$(BASEEXT).bs $(PERM_RW)


# --- MakeMaker dynamic section:
dynamic :: static
	@$(NOOP)


# --- MakeMaker dynamic_lib section:
dynamic_lib :: static_lib
	@$(NOOP)


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:
$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)$(DFSEP).exists
	$(RM_F) "$@"
	$(FULL_AR) $(AR_STATIC_ARGS) "$@" $(OBJECT)
	$(RANLIB) "$@"
	$(CHMOD) $(PERM_RWX) $@
	$(NOECHO) $(ECHO) "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)$(DFSEP)extralibs.ld


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--" --center "perl/Tk Documentation" --release "Tk$(VERSION)"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all config 
	$(NOECHO) $(NOOP)




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  $(BASEEXT).bso $(BASEEXT).def \
	  $(BASEEXT).exp $(BASEEXT).x \
	  $(BOOTSTRAP) $(INST_ARCHAUTODIR)/extralibs.all \
	  $(INST_ARCHAUTODIR)/extralibs.ld $(MAKE_APERL_FILE) \
	  *$(LIB_EXT) *$(OBJ_EXT) \
	  *perl.core MYMETA.json \
	  MYMETA.yml blibdirs.ts \
	  core core.*perl.*.? \
	  core.[0-9] core.[0-9][0-9] \
	  core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] \
	  core.[0-9][0-9][0-9][0-9][0-9] lib$(BASEEXT).def \
	  mon.out perl \
	  perl$(EXE_EXT) perl.exe \
	  perlmain.c pm_to_blib \
	  pm_to_blib.ts so_locations \
	  tmon.out 
	- $(RM_RF) \
	  *.bak blib \
	  libpTk$(LIB_EXT) 
	  $(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
# so clean is forced to complete before realclean_subdirs runs
realclean_subdirs : clean
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge :: realclean_subdirs
	- $(RM_F) \
	  $(FIRST_MAKEFILE) $(MAKEFILE_OLD) \
	  $(OBJECT) 
	- $(RM_RF) \
	  $(DISTVNAME) 

mungeclean ::
	$(RM_F) tkTableEdit.c \
	tkTableversion.h \
	tkTable.c \
	tkTable.h \
	version.h \
	tkTableCell.c \
	tkTableCellSort.c \
	tkTableTag.c \
	mm.h \
	tkTableCmds.c \
	tkTableUtil.c \
	tkTableWin.c


# --- MakeMaker metafile section:
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	$(NOECHO) $(ECHO) '---' > META_new.yml
	$(NOECHO) $(ECHO) 'abstract: unknown' >> META_new.yml
	$(NOECHO) $(ECHO) 'author:' >> META_new.yml
	$(NOECHO) $(ECHO) '  - unknown' >> META_new.yml
	$(NOECHO) $(ECHO) 'build_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'configure_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'dynamic_config: 1' >> META_new.yml
	$(NOECHO) $(ECHO) 'generated_by: '\''ExtUtils::MakeMaker version 7.62, CPAN::Meta::Converter version 2.150010'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'license: unknown' >> META_new.yml
	$(NOECHO) $(ECHO) 'meta-spec:' >> META_new.yml
	$(NOECHO) $(ECHO) '  url: http://module-build.sourceforge.net/META-spec-v1.4.html' >> META_new.yml
	$(NOECHO) $(ECHO) '  version: '\''1.4'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'name: Tk-pTk' >> META_new.yml
	$(NOECHO) $(ECHO) 'no_index:' >> META_new.yml
	$(NOECHO) $(ECHO) '  directory:' >> META_new.yml
	$(NOECHO) $(ECHO) '    - t' >> META_new.yml
	$(NOECHO) $(ECHO) '    - inc' >> META_new.yml
	$(NOECHO) $(ECHO) 'version: '\''1.29'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'x_serialization_backend: '\''CPAN::Meta::YAML version 0.018'\''' >> META_new.yml
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) Generating META.json
	$(NOECHO) $(ECHO) '{' > META_new.json
	$(NOECHO) $(ECHO) '   "abstract" : "unknown",' >> META_new.json
	$(NOECHO) $(ECHO) '   "author" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "unknown"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "dynamic_config" : 1,' >> META_new.json
	$(NOECHO) $(ECHO) '   "generated_by" : "ExtUtils::MakeMaker version 7.62, CPAN::Meta::Converter version 2.150010",' >> META_new.json
	$(NOECHO) $(ECHO) '   "license" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "unknown"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "meta-spec" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",' >> META_new.json
	$(NOECHO) $(ECHO) '      "version" : 2' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "name" : "Tk-pTk",' >> META_new.json
	$(NOECHO) $(ECHO) '   "no_index" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "directory" : [' >> META_new.json
	$(NOECHO) $(ECHO) '         "t",' >> META_new.json
	$(NOECHO) $(ECHO) '         "inc"' >> META_new.json
	$(NOECHO) $(ECHO) '      ]' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "prereqs" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "build" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "configure" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "release_status" : "stable",' >> META_new.json
	$(NOECHO) $(ECHO) '   "version" : "1.29",' >> META_new.json
	$(NOECHO) $(ECHO) '   "x_serialization_backend" : "JSON::PP version 4.06"' >> META_new.json
	$(NOECHO) $(ECHO) '}' >> META_new.json
	-$(NOECHO) $(MV) META_new.json $(DISTVNAME)/META.json


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section skipped.

# --- MakeMaker dist_core section skipped.

# --- MakeMaker distdir section skipped.

# --- MakeMaker dist_test section skipped.

# --- MakeMaker dist_ci section skipped.

# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.yml to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.json to MANIFEST: $${'\''@'\''}"' --



# --- MakeMaker distsignature section:
distsignature : distmeta
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section skipped.

# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:
PERL_HDRS = \
        $(PERL_INCDEP)/EXTERN.h            \
        $(PERL_INCDEP)/INTERN.h            \
        $(PERL_INCDEP)/XSUB.h            \
        $(PERL_INCDEP)/av.h            \
        $(PERL_INCDEP)/bitcount.h            \
        $(PERL_INCDEP)/charclass_invlists.h            \
        $(PERL_INCDEP)/config.h            \
        $(PERL_INCDEP)/cop.h            \
        $(PERL_INCDEP)/cv.h            \
        $(PERL_INCDEP)/dosish.h            \
        $(PERL_INCDEP)/ebcdic_tables.h            \
        $(PERL_INCDEP)/embed.h            \
        $(PERL_INCDEP)/embedvar.h            \
        $(PERL_INCDEP)/fakesdio.h            \
        $(PERL_INCDEP)/feature.h            \
        $(PERL_INCDEP)/form.h            \
        $(PERL_INCDEP)/git_version.h            \
        $(PERL_INCDEP)/gv.h            \
        $(PERL_INCDEP)/handy.h            \
        $(PERL_INCDEP)/hv.h            \
        $(PERL_INCDEP)/hv_func.h            \
        $(PERL_INCDEP)/hv_macro.h            \
        $(PERL_INCDEP)/inline.h            \
        $(PERL_INCDEP)/intrpvar.h            \
        $(PERL_INCDEP)/invlist_inline.h            \
        $(PERL_INCDEP)/iperlsys.h            \
        $(PERL_INCDEP)/keywords.h            \
        $(PERL_INCDEP)/l1_char_class_tab.h            \
        $(PERL_INCDEP)/malloc_ctl.h            \
        $(PERL_INCDEP)/metaconfig.h            \
        $(PERL_INCDEP)/mg.h            \
        $(PERL_INCDEP)/mg_data.h            \
        $(PERL_INCDEP)/mg_raw.h            \
        $(PERL_INCDEP)/mg_vtable.h            \
        $(PERL_INCDEP)/mydtrace.h            \
        $(PERL_INCDEP)/nostdio.h            \
        $(PERL_INCDEP)/op.h            \
        $(PERL_INCDEP)/op_reg_common.h            \
        $(PERL_INCDEP)/opcode.h            \
        $(PERL_INCDEP)/opnames.h            \
        $(PERL_INCDEP)/overload.h            \
        $(PERL_INCDEP)/pad.h            \
        $(PERL_INCDEP)/parser.h            \
        $(PERL_INCDEP)/patchlevel.h            \
        $(PERL_INCDEP)/perl.h            \
        $(PERL_INCDEP)/perl_inc_macro.h            \
        $(PERL_INCDEP)/perl_langinfo.h            \
        $(PERL_INCDEP)/perl_siphash.h            \
        $(PERL_INCDEP)/perlapi.h            \
        $(PERL_INCDEP)/perlio.h            \
        $(PERL_INCDEP)/perliol.h            \
        $(PERL_INCDEP)/perlsdio.h            \
        $(PERL_INCDEP)/perlvars.h            \
        $(PERL_INCDEP)/perly.h            \
        $(PERL_INCDEP)/pp.h            \
        $(PERL_INCDEP)/pp_proto.h            \
        $(PERL_INCDEP)/proto.h            \
        $(PERL_INCDEP)/reentr.h            \
        $(PERL_INCDEP)/regcharclass.h            \
        $(PERL_INCDEP)/regcomp.h            \
        $(PERL_INCDEP)/regexp.h            \
        $(PERL_INCDEP)/regnodes.h            \
        $(PERL_INCDEP)/sbox32_hash.h            \
        $(PERL_INCDEP)/scope.h            \
        $(PERL_INCDEP)/sv.h            \
        $(PERL_INCDEP)/thread.h            \
        $(PERL_INCDEP)/time64.h            \
        $(PERL_INCDEP)/time64_config.h            \
        $(PERL_INCDEP)/uconfig.h            \
        $(PERL_INCDEP)/uni_keywords.h            \
        $(PERL_INCDEP)/unicode_constants.h            \
        $(PERL_INCDEP)/unixish.h            \
        $(PERL_INCDEP)/utf8.h            \
        $(PERL_INCDEP)/utfebcdic.h            \
        $(PERL_INCDEP)/util.h            \
        $(PERL_INCDEP)/uudmap.h            \
        $(PERL_INCDEP)/vutil.h            \
        $(PERL_INCDEP)/warnings.h            \
        $(PERL_INCDEP)/zaphod32_hash.h            

$(OBJECT) : $(PERL_HDRS)

tkTable$(OBJ_EXT) : tkTable.c tkTable.h tkTableversion.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Xlib.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Xlib.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Xlib_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tcl.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclPlatDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkConfig.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkInt.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkIntDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkUnixPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkVMacro.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk_f.h

tkTableCell$(OBJ_EXT) : tkTableCell.c tkTable.h tkTableversion.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tcl.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclPlatDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkConfig.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkUnixPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkVMacro.h

tkTableCellSort$(OBJ_EXT) : tkTableCellSort.c tkTable.h \
 tkTableversion.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Xlib.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Xlib.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Xlib_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tcl.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclPlatDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkConfig.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkUnixPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkVMacro.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk_f.h

tkTableCmds$(OBJ_EXT) : tkTableCmds.c tkTable.h tkTableversion.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tcl.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclPlatDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkConfig.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkUnixPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkVMacro.h

tkTableEdit$(OBJ_EXT) : tkTableEdit.c tkTable.h tkTableversion.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tcl.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclPlatDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkConfig.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkUnixPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkVMacro.h

tkTableTag$(OBJ_EXT) : tkTableTag.c tkTable.h tkTableversion.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tcl.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclPlatDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkConfig.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkUnixPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkVMacro.h

tkTableUtil$(OBJ_EXT) : tkTableUtil.c tkTable.h tkTableversion.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Xlib.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Xlib.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Xlib_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tcl.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclPlatDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkConfig.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkUnixPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkVMacro.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk_f.h

tkTableWin$(OBJ_EXT) : tkTableWin.c tkTable.h tkTableversion.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/Lang.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tcl.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tclPlatDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tk.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkConfig.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkDecls.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.m \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent.t \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkEvent_f.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkUnixPort.h \
 /opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/pTk/tkVMacro.h


# --- MakeMaker makefile section:


# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP) ../../../../../opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/Config.pm ../../../../../opt/local/lib/perl5/vendor_perl/5.34/darwin-thread-multi-2level/Tk/MMutil.pm
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL "BINARY_LOCATION=darwin-thread-multi-2level/Tk1.29-PPM.tar.gz"
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = ../perl
FULLPERL      = "/opt/local/bin/perl5.34"
MAP_PERLINC   = "-I../blib/arch" "-I../blib/lib" "-I/opt/local/lib/perl5/5.34/darwin-thread-multi-2level" "-I/opt/local/lib/perl5/5.34"


# --- MakeMaker test section:

test :: 
	@echo 'No tests defined for $(NAME)'
 

# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="Tk-pTk" VERSION="1.29">' > Tk-pTk.ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT></ABSTRACT>' >> Tk-pTk.ppd
	$(NOECHO) $(ECHO) '    <AUTHOR></AUTHOR>' >> Tk-pTk.ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> Tk-pTk.ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="darwin-thread-multi-2level-5.34" />' >> Tk-pTk.ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> Tk-pTk.ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> Tk-pTk.ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> Tk-pTk.ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'mm.h' '$(INST_ARCHLIBDIR)/pTk/mm.h' \
	  'tkTable.h' '$(INST_ARCHLIBDIR)/pTk/tkTable.h' \
	  'tkTableversion.h' '$(INST_ARCHLIBDIR)/pTk/tkTableversion.h' \
	  'version.h' '$(INST_ARCHLIBDIR)/pTk/version.h' 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:

# here so even if top_targets is overridden, these will still be defined
# gmake will silently still work if any are .PHONY-ed but nmake won't

static ::
	$(NOECHO) $(NOOP)

dynamic ::
	$(NOECHO) $(NOOP)

config ::
	$(NOECHO) $(NOOP)


# --- MakeMaker postamble section:
config :: $(C_FILES) $(H_FILES)
	@$(NOOP)
# Begin Munging dependencies
mm.h : mTk/Tktable/mm.h $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/mm.h mm.h
tkTable.c : mTk/Tktable/tkTable.c $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/tkTable.c tkTable.c
tkTable.h : mTk/Tktable/tkTable.h $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/tkTable.h tkTable.h
tkTableCell.c : mTk/Tktable/tkTableCell.c $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/tkTableCell.c tkTableCell.c
tkTableCellSort.c : mTk/Tktable/tkTableCellSort.c $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/tkTableCellSort.c tkTableCellSort.c
tkTableCmds.c : mTk/Tktable/tkTableCmds.c $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/tkTableCmds.c tkTableCmds.c
tkTableEdit.c : mTk/Tktable/tkTableEdit.c $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/tkTableEdit.c tkTableEdit.c
tkTableTag.c : mTk/Tktable/tkTableTag.c $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/tkTableTag.c tkTableTag.c
tkTableUtil.c : mTk/Tktable/tkTableUtil.c $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/tkTableUtil.c tkTableUtil.c
tkTableWin.c : mTk/Tktable/tkTableWin.c $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/tkTableWin.c tkTableWin.c
tkTableversion.h : mTk/Tktable/tkTableversion.h $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/tkTableversion.h tkTableversion.h
version.h : mTk/Tktable/version.h $(TKDIR)/pTk/Tcl-pTk
	$(PERL) $(TKDIR)/pTk/Tcl-pTk mTk/Tktable/version.h version.h
# End Munging dependencies

$(INST_ARCHLIBDIR)/pTk$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIBDIR)/pTk
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIBDIR)/pTk
	$(NOECHO) $(TOUCH) $(INST_ARCHLIBDIR)/pTk$(DFSEP).exists

$(INST_ARCHLIBDIR)/pTk/compat$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIBDIR)/pTk/compat
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIBDIR)/pTk/compat
	$(NOECHO) $(TOUCH) $(INST_ARCHLIBDIR)/pTk/compat$(DFSEP).exists

config :: $(INST_ARCHLIBDIR)/pTk$(DFSEP).exists \
	$(INST_ARCHLIBDIR)/pTk/compat$(DFSEP).exists
	@$(NOOP)


	@$(NOOP)



# End.
