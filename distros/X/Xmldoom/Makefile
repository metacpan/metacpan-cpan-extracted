# This Makefile is for the Xmldoom extension to perl.
#
# It was generated automatically by MakeMaker version
# 6.17 (Revision: 1.133) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: (q[dist])
#
#   MakeMaker Parameters:

#     ABSTRACT => q[Xmldoom is a framework that allows you to bind database tables to Perl objects, a technique commonly referred to as object persistence, similar in purpose to Propel and Apache Torque]
#     AUTHOR => q[David Snopek]
#     DIR => []
#     DISTNAME => q[Xmldoom]
#     EXE_FILES => [q[bin/xmldoom-generate], q[bin/xmldoom-schema]]
#     NAME => q[Xmldoom]
#     NO_META => q[1]
#     PL_FILES => {  }
#     PREREQ_PM => { Scalar::Util=>q[0], XML::SAX=>q[0], DBD::SQLite=>q[0], Exception::Class::TryCatch=>q[0], Module::Runtime=>q[0], XML::DOM=>q[0], POSIX::strptime=>q[0], Exception::Class::DBI=>q[0], Getopt::Long=>q[0], SQL::Translator=>q[0], IO::File=>q[0], XML::GDOME=>q[0], Test::Class=>q[0], Data::Dumper=>q[0], ExtUtils::MakeMaker=>q[6.11], Callback=>q[0], DBIx::Romani=>q[0.0.16], Carp=>q[0], Exception::Class=>q[0], Date::Calc=>q[0], Test::More=>q[0], XML::Writer=>q[0], Module::Util=>q[0], XML::SAX::ExpatXS=>q[0], XML::Writer::String=>q[0] }
#     VERSION => q[0.0.16]
#     dist => { PREOP=>q[$(PERL) -I. -MModule::Install::Admin -e "dist_preop(q($(DISTVNAME)))"] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/lib/perl5/5.8.7/i686-linux/Config.pm)

# They may have been overridden via Makefile.PL or on the command line
AR = ar
CC = i686-pc-linux-gnu-gcc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -rdynamic
DLEXT = so
DLSRC = dl_dlopen.xs
LD = i686-pc-linux-gnu-gcc
LDDLFLAGS = -shared -L/usr/local/lib
LDFLAGS =  -L/usr/local/lib
LIBC = /lib/libc-2.3.5.so
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 2.6.10-gentoo-r6
RANLIB = :
SITELIBEXP = /usr/lib/perl5/site_perl/5.8.7
SITEARCHEXP = /usr/lib/perl5/site_perl/5.8.7/i686-linux
SO = so
EXE_EXT = 
FULL_AR = /usr/bin/ar
VENDORARCHEXP = /usr/lib/perl5/vendor_perl/5.8.7/i686-linux
VENDORLIBEXP = /usr/lib/perl5/vendor_perl/5.8.7


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
NAME = Xmldoom
NAME_SYM = Xmldoom
VERSION = 0.0.16
VERSION_MACRO = VERSION
VERSION_SYM = 0_0_16
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 0.0.16
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1
MAN3EXT = 3pm
INSTALLDIRS = site
DESTDIR = 
PREFIX = 
PERLPREFIX = /usr
SITEPREFIX = /usr
VENDORPREFIX = /usr
INSTALLPRIVLIB = $(PERLPREFIX)/lib/perl5/5.8.7
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = $(SITEPREFIX)/lib/perl5/site_perl/5.8.7
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = $(VENDORPREFIX)/lib/perl5/vendor_perl/5.8.7
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = $(PERLPREFIX)/lib/perl5/5.8.7/i686-linux
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = $(SITEPREFIX)/lib/perl5/site_perl/5.8.7/i686-linux
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = $(VENDORPREFIX)/lib/perl5/vendor_perl/5.8.7/i686-linux
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = $(PERLPREFIX)/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = $(SITEPREFIX)/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = $(VENDORPREFIX)/bin
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = $(PERLPREFIX)/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLMAN1DIR = $(PERLPREFIX)/share/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = $(SITEPREFIX)/share/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = $(VENDORPREFIX)/share/man/man1
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = $(PERLPREFIX)/share/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = $(SITEPREFIX)/share/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = $(VENDORPREFIX)/share/man/man3
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB =
PERL_ARCHLIB = /usr/lib/perl5/5.8.7/i686-linux
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = $(FIRST_MAKEFILE).old
MAKE_APERL_FILE = $(FIRST_MAKEFILE).aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/lib/perl5/5.8.7/i686-linux/CORE
PERL = /usr/bin/perl5.8.7 "-Iinc"
FULLPERL = /usr/bin/perl5.8.7 "-Iinc"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /usr/lib/perl5/5.8.7/ExtUtils/MakeMaker.pm
MM_VERSION  = 6.17
MM_REVISION = 1.133

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = Xmldoom
BASEEXT = Xmldoom
PARENT_NAME = 
DLBASE = $(BASEEXT)
VERSION_FROM = 
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = 
MAN3PODS = lib/SQL/Translator/Parser/XML/Propel.pm \
	lib/SQL/Translator/Parser/XML/Torque.pm \
	lib/SQL/Translator/Parser/XML/Xmldoom.pm \
	lib/SQL/Translator/Producer/XML/Propel.pm \
	lib/SQL/Translator/Producer/XML/Torque.pm \
	lib/SQL/Translator/Producer/XML/Xmldoom.pm \
	lib/Thread/Shared.pm \
	lib/Xmldoom.pm \
	lib/Xmldoom/Object.pm

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)$(DIRFILESEP)Config.pm $(PERL_INC)$(DIRFILESEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)
INST_ARCHLIBDIR  = $(INST_ARCHLIB)

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/SQL/Translator/Parser/XML/Propel.pm \
	lib/SQL/Translator/Parser/XML/Torque.pm \
	lib/SQL/Translator/Parser/XML/Xmldoom.pm \
	lib/SQL/Translator/Producer/XML/Propel.pm \
	lib/SQL/Translator/Producer/XML/Torque.pm \
	lib/SQL/Translator/Producer/XML/Xmldoom.pm \
	lib/Thread/Shared.pm \
	lib/Thread/Shared/Array.pm \
	lib/Thread/Shared/Hash.pm \
	lib/Xmldoom.pm \
	lib/Xmldoom/Criteria.pm \
	lib/Xmldoom/Criteria/Attribute.pm \
	lib/Xmldoom/Criteria/Comparison.pm \
	lib/Xmldoom/Criteria/ExplicitJoinVisitor.pm \
	lib/Xmldoom/Criteria/Literal.pm \
	lib/Xmldoom/Criteria/Property.pm \
	lib/Xmldoom/Criteria/Search.pm \
	lib/Xmldoom/Criteria/UnknownObject.pm \
	lib/Xmldoom/Criteria/XML.pm \
	lib/Xmldoom/Definition.pm \
	lib/Xmldoom/Definition/Database.pm \
	lib/Xmldoom/Definition/Link.pm \
	lib/Xmldoom/Definition/LinkTree.pm \
	lib/Xmldoom/Definition/Object.pm \
	lib/Xmldoom/Definition/PerlModuleParser.pm \
	lib/Xmldoom/Definition/Property.pm \
	lib/Xmldoom/Definition/Property/Object.pm \
	lib/Xmldoom/Definition/Property/PlaceHolder.pm \
	lib/Xmldoom/Definition/Property/Simple.pm \
	lib/Xmldoom/Definition/SAXHandler.pm \
	lib/Xmldoom/ORB/Apache.pm \
	lib/Xmldoom/ORB/Definition.pm \
	lib/Xmldoom/ORB/Definition/JSON.pm \
	lib/Xmldoom/ORB/Transport.pm \
	lib/Xmldoom/ORB/Transport/JSON.pm \
	lib/Xmldoom/ORB/Transport/XML.pm \
	lib/Xmldoom/Object.pm \
	lib/Xmldoom/Object/Attribute.pm \
	lib/Xmldoom/Object/LinkAttribute.pm \
	lib/Xmldoom/Object/Property.pm \
	lib/Xmldoom/Object/XMLGenerator.pm \
	lib/Xmldoom/ResultSet.pm \
	lib/Xmldoom/Schema.pm \
	lib/Xmldoom/Schema/Column.pm \
	lib/Xmldoom/Schema/ForeignKey.pm \
	lib/Xmldoom/Schema/Parser.pm \
	lib/Xmldoom/Schema/SAXHandler.pm \
	lib/Xmldoom/Schema/Table.pm \
	lib/Xmldoom/Threads.pm

PM_TO_BLIB = lib/Xmldoom/Definition/LinkTree.pm \
	blib/lib/Xmldoom/Definition/LinkTree.pm \
	lib/Xmldoom/Definition/PerlModuleParser.pm \
	blib/lib/Xmldoom/Definition/PerlModuleParser.pm \
	lib/Xmldoom/Definition/Link.pm \
	blib/lib/Xmldoom/Definition/Link.pm \
	lib/Xmldoom/Criteria/XML.pm \
	blib/lib/Xmldoom/Criteria/XML.pm \
	lib/SQL/Translator/Producer/XML/Torque.pm \
	blib/lib/SQL/Translator/Producer/XML/Torque.pm \
	lib/Xmldoom/Criteria/Property.pm \
	blib/lib/Xmldoom/Criteria/Property.pm \
	lib/Xmldoom/ResultSet.pm \
	blib/lib/Xmldoom/ResultSet.pm \
	lib/Xmldoom/Threads.pm \
	blib/lib/Xmldoom/Threads.pm \
	lib/SQL/Translator/Producer/XML/Propel.pm \
	blib/lib/SQL/Translator/Producer/XML/Propel.pm \
	lib/Xmldoom/Schema/Table.pm \
	blib/lib/Xmldoom/Schema/Table.pm \
	lib/Xmldoom/Schema/SAXHandler.pm \
	blib/lib/Xmldoom/Schema/SAXHandler.pm \
	lib/SQL/Translator/Parser/XML/Propel.pm \
	blib/lib/SQL/Translator/Parser/XML/Propel.pm \
	lib/Xmldoom/Criteria/Search.pm \
	blib/lib/Xmldoom/Criteria/Search.pm \
	lib/Xmldoom/Definition/Property.pm \
	blib/lib/Xmldoom/Definition/Property.pm \
	lib/Xmldoom/Object/LinkAttribute.pm \
	blib/lib/Xmldoom/Object/LinkAttribute.pm \
	lib/Xmldoom/Object/Attribute.pm \
	blib/lib/Xmldoom/Object/Attribute.pm \
	lib/Xmldoom/Criteria/Comparison.pm \
	blib/lib/Xmldoom/Criteria/Comparison.pm \
	lib/Xmldoom/Schema/ForeignKey.pm \
	blib/lib/Xmldoom/Schema/ForeignKey.pm \
	lib/Xmldoom/Criteria/ExplicitJoinVisitor.pm \
	blib/lib/Xmldoom/Criteria/ExplicitJoinVisitor.pm \
	lib/Xmldoom/Definition/Object.pm \
	blib/lib/Xmldoom/Definition/Object.pm \
	lib/Thread/Shared/Array.pm \
	blib/lib/Thread/Shared/Array.pm \
	lib/Xmldoom/Definition/SAXHandler.pm \
	blib/lib/Xmldoom/Definition/SAXHandler.pm \
	lib/Xmldoom/Criteria/UnknownObject.pm \
	blib/lib/Xmldoom/Criteria/UnknownObject.pm \
	lib/Xmldoom/Schema.pm \
	blib/lib/Xmldoom/Schema.pm \
	lib/Xmldoom/Definition/Property/Simple.pm \
	blib/lib/Xmldoom/Definition/Property/Simple.pm \
	lib/Xmldoom/Definition/Property/PlaceHolder.pm \
	blib/lib/Xmldoom/Definition/Property/PlaceHolder.pm \
	lib/Thread/Shared/Hash.pm \
	blib/lib/Thread/Shared/Hash.pm \
	lib/Xmldoom/Schema/Parser.pm \
	blib/lib/Xmldoom/Schema/Parser.pm \
	lib/Xmldoom/ORB/Definition/JSON.pm \
	blib/lib/Xmldoom/ORB/Definition/JSON.pm \
	lib/Xmldoom/Schema/Column.pm \
	blib/lib/Xmldoom/Schema/Column.pm \
	lib/Xmldoom/Criteria.pm \
	blib/lib/Xmldoom/Criteria.pm \
	lib/SQL/Translator/Parser/XML/Torque.pm \
	blib/lib/SQL/Translator/Parser/XML/Torque.pm \
	lib/Xmldoom/Object/Property.pm \
	blib/lib/Xmldoom/Object/Property.pm \
	lib/SQL/Translator/Producer/XML/Xmldoom.pm \
	blib/lib/SQL/Translator/Producer/XML/Xmldoom.pm \
	lib/SQL/Translator/Parser/XML/Xmldoom.pm \
	blib/lib/SQL/Translator/Parser/XML/Xmldoom.pm \
	lib/Xmldoom/Definition/Database.pm \
	blib/lib/Xmldoom/Definition/Database.pm \
	lib/Xmldoom/ORB/Transport.pm \
	blib/lib/Xmldoom/ORB/Transport.pm \
	lib/Xmldoom/ORB/Transport/JSON.pm \
	blib/lib/Xmldoom/ORB/Transport/JSON.pm \
	lib/Xmldoom/Definition/Property/Object.pm \
	blib/lib/Xmldoom/Definition/Property/Object.pm \
	lib/Xmldoom/ORB/Apache.pm \
	blib/lib/Xmldoom/ORB/Apache.pm \
	lib/Xmldoom/Criteria/Literal.pm \
	blib/lib/Xmldoom/Criteria/Literal.pm \
	lib/Xmldoom/Object.pm \
	blib/lib/Xmldoom/Object.pm \
	lib/Xmldoom/Criteria/Attribute.pm \
	blib/lib/Xmldoom/Criteria/Attribute.pm \
	lib/Xmldoom.pm \
	blib/lib/Xmldoom.pm \
	lib/Xmldoom/ORB/Definition.pm \
	blib/lib/Xmldoom/ORB/Definition.pm \
	lib/Xmldoom/Object/XMLGenerator.pm \
	blib/lib/Xmldoom/Object/XMLGenerator.pm \
	lib/Thread/Shared.pm \
	blib/lib/Thread/Shared.pm \
	lib/Xmldoom/Definition.pm \
	blib/lib/Xmldoom/Definition.pm \
	lib/Xmldoom/ORB/Transport/XML.pm \
	blib/lib/Xmldoom/ORB/Transport/XML.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 1.42
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERLRUN)  -e 'use AutoSplit;  autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1)'



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(SHELL) -c true
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(PERLRUN) "-MExtUtils::Command" -e mkpath
EQUALIZE_TIMESTAMP = $(PERLRUN) "-MExtUtils::Command" -e eqtime
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(PERLRUN) -MExtUtils::Install -e 'install({@ARGV}, '\''$(VERBINST)'\'', 0, '\''$(UNINST)'\'');'
DOC_INSTALL = $(PERLRUN) "-MExtUtils::Command::MM" -e perllocal_install
UNINSTALL = $(PERLRUN) "-MExtUtils::Command::MM" -e uninstall
WARN_IF_OLD_PACKLIST = $(PERLRUN) "-MExtUtils::Command::MM" -e warn_if_old_packlist


# --- MakeMaker makemakerdflt section:
makemakerdflt: all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(PERL) -I. -MModule::Install::Admin -e "dist_preop(q($(DISTVNAME)))"
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = Xmldoom
DISTVNAME = Xmldoom-0.0.16


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIB="$(LIB)"\
	LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	OPTIMIZE="$(OPTIMIZE)"\
	PASTHRU_DEFINE="$(PASTHRU_DEFINE)"\
	PASTHRU_INC="$(PASTHRU_INC)"


# --- MakeMaker special_targets section:
.SUFFIXES: .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)


pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) $(INST_LIBDIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)

config :: $(INST_ARCHAUTODIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)

config :: $(INST_AUTODIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)

$(INST_AUTODIR)/.exists :: /usr/lib/perl5/5.8.7/i686-linux/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/lib/perl5/5.8.7/i686-linux/CORE/perl.h $(INST_AUTODIR)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_AUTODIR)

$(INST_LIBDIR)/.exists :: /usr/lib/perl5/5.8.7/i686-linux/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/lib/perl5/5.8.7/i686-linux/CORE/perl.h $(INST_LIBDIR)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_LIBDIR)

$(INST_ARCHAUTODIR)/.exists :: /usr/lib/perl5/5.8.7/i686-linux/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/lib/perl5/5.8.7/i686-linux/CORE/perl.h $(INST_ARCHAUTODIR)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_ARCHAUTODIR)

config :: $(INST_MAN3DIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)


$(INST_MAN3DIR)/.exists :: /usr/lib/perl5/5.8.7/i686-linux/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/lib/perl5/5.8.7/i686-linux/CORE/perl.h $(INST_MAN3DIR)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_MAN3DIR)

help:
	perldoc ExtUtils::MakeMaker


# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) $(INST_DYNAMIC) $(INST_BOOT)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all  \
	lib/SQL/Translator/Producer/XML/Torque.pm \
	lib/SQL/Translator/Parser/XML/Torque.pm \
	lib/Xmldoom/Object.pm \
	lib/SQL/Translator/Producer/XML/Xmldoom.pm \
	lib/Xmldoom.pm \
	lib/SQL/Translator/Producer/XML/Propel.pm \
	lib/SQL/Translator/Parser/XML/Propel.pm \
	lib/Thread/Shared.pm \
	lib/SQL/Translator/Parser/XML/Xmldoom.pm \
	lib/SQL/Translator/Producer/XML/Torque.pm \
	lib/SQL/Translator/Parser/XML/Torque.pm \
	lib/Xmldoom/Object.pm \
	lib/SQL/Translator/Producer/XML/Xmldoom.pm \
	lib/Xmldoom.pm \
	lib/SQL/Translator/Producer/XML/Propel.pm \
	lib/SQL/Translator/Parser/XML/Propel.pm \
	lib/Thread/Shared.pm \
	lib/SQL/Translator/Parser/XML/Xmldoom.pm
	$(NOECHO) $(POD2MAN) --section=3 --perm_rw=$(PERM_RW)\
	  lib/SQL/Translator/Producer/XML/Torque.pm $(INST_MAN3DIR)/SQL::Translator::Producer::XML::Torque.$(MAN3EXT) \
	  lib/SQL/Translator/Parser/XML/Torque.pm $(INST_MAN3DIR)/SQL::Translator::Parser::XML::Torque.$(MAN3EXT) \
	  lib/Xmldoom/Object.pm $(INST_MAN3DIR)/Xmldoom::Object.$(MAN3EXT) \
	  lib/SQL/Translator/Producer/XML/Xmldoom.pm $(INST_MAN3DIR)/SQL::Translator::Producer::XML::Xmldoom.$(MAN3EXT) \
	  lib/Xmldoom.pm $(INST_MAN3DIR)/Xmldoom.$(MAN3EXT) \
	  lib/SQL/Translator/Producer/XML/Propel.pm $(INST_MAN3DIR)/SQL::Translator::Producer::XML::Propel.$(MAN3EXT) \
	  lib/SQL/Translator/Parser/XML/Propel.pm $(INST_MAN3DIR)/SQL::Translator::Parser::XML::Propel.$(MAN3EXT) \
	  lib/Thread/Shared.pm $(INST_MAN3DIR)/Thread::Shared.$(MAN3EXT) \
	  lib/SQL/Translator/Parser/XML/Xmldoom.pm $(INST_MAN3DIR)/SQL::Translator::Parser::XML::Xmldoom.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

$(INST_SCRIPT)/.exists :: /usr/lib/perl5/5.8.7/i686-linux/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/lib/perl5/5.8.7/i686-linux/CORE/perl.h $(INST_SCRIPT)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)

EXE_FILES = bin/xmldoom-generate bin/xmldoom-schema

FIXIN = $(PERLRUN) "-MExtUtils::MY" -e "MY->fixin(shift)"

pure_all :: $(INST_SCRIPT)/xmldoom-schema $(INST_SCRIPT)/xmldoom-generate
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) $(INST_SCRIPT)/xmldoom-schema $(INST_SCRIPT)/xmldoom-generate

$(INST_SCRIPT)/xmldoom-schema: bin/xmldoom-schema $(FIRST_MAKEFILE) $(INST_SCRIPT)/.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/xmldoom-schema
	$(CP) bin/xmldoom-schema $(INST_SCRIPT)/xmldoom-schema
	$(FIXIN) $(INST_SCRIPT)/xmldoom-schema
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/xmldoom-schema

$(INST_SCRIPT)/xmldoom-generate: bin/xmldoom-generate $(FIRST_MAKEFILE) $(INST_SCRIPT)/.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/xmldoom-generate
	$(CP) bin/xmldoom-generate $(INST_SCRIPT)/xmldoom-generate
	$(FIXIN) $(INST_SCRIPT)/xmldoom-generate
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/xmldoom-generate


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	-$(RM_RF) ./blib $(MAKE_APERL_FILE) $(INST_ARCHAUTODIR)/extralibs.all $(INST_ARCHAUTODIR)/extralibs.ld perlmain.c tmon.out mon.out so_locations pm_to_blib *$(OBJ_EXT) *$(LIB_EXT) perl.exe perl perl$(EXE_EXT) $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).def lib$(BASEEXT).def $(BASEEXT).exp $(BASEEXT).x core core.*perl.*.? *perl.core core.[0-9] core.[0-9][0-9] core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9][0-9]
	-$(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
realclean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean realclean_subdirs
	$(RM_RF) $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	$(RM_RF) $(DISTVNAME)
	$(RM_F)  blib/lib/Xmldoom/Schema/Column.pm blib/lib/Thread/Shared.pm blib/lib/Xmldoom/Criteria/Property.pm blib/lib/Xmldoom/Definition/SAXHandler.pm blib/lib/Xmldoom/ORB/Apache.pm
	$(RM_F) blib/lib/SQL/Translator/Parser/XML/Torque.pm blib/lib/Xmldoom/Definition/Property.pm blib/lib/Xmldoom/Criteria/Comparison.pm blib/lib/Xmldoom/Criteria/ExplicitJoinVisitor.pm $(FIRST_MAKEFILE)
	$(RM_F) blib/lib/Xmldoom/Definition/Property/PlaceHolder.pm blib/lib/Xmldoom/ORB/Transport/XML.pm blib/lib/Xmldoom/Object.pm blib/lib/Xmldoom/ORB/Transport.pm blib/lib/Xmldoom/Threads.pm
	$(RM_F) blib/lib/SQL/Translator/Parser/XML/Xmldoom.pm blib/lib/Xmldoom/Criteria/UnknownObject.pm blib/lib/Xmldoom/Definition/PerlModuleParser.pm blib/lib/Xmldoom/Definition/Database.pm
	$(RM_F) blib/lib/SQL/Translator/Producer/XML/Torque.pm blib/lib/SQL/Translator/Producer/XML/Propel.pm blib/lib/Xmldoom/Criteria/XML.pm blib/lib/Xmldoom.pm blib/lib/Thread/Shared/Array.pm
	$(RM_F) blib/lib/Xmldoom/ResultSet.pm blib/lib/Xmldoom/Definition/Property/Object.pm blib/lib/Xmldoom/Definition/Property/Simple.pm $(MAKEFILE_OLD) blib/lib/Xmldoom/Definition/Link.pm
	$(RM_F) blib/lib/Xmldoom/Schema/SAXHandler.pm blib/lib/Xmldoom/Criteria/Attribute.pm blib/lib/Xmldoom/Object/XMLGenerator.pm blib/lib/Xmldoom/Schema/Table.pm blib/lib/Xmldoom/Definition/LinkTree.pm
	$(RM_F) blib/lib/SQL/Translator/Producer/XML/Xmldoom.pm blib/lib/Xmldoom/ORB/Definition.pm blib/lib/Xmldoom/Criteria/Search.pm blib/lib/Xmldoom/Criteria.pm blib/lib/Thread/Shared/Hash.pm
	$(RM_F) blib/lib/Xmldoom/Definition/Object.pm blib/lib/Xmldoom/Schema/ForeignKey.pm blib/lib/Xmldoom/Schema/Parser.pm blib/lib/Xmldoom/Schema.pm blib/lib/Xmldoom/Object/LinkAttribute.pm
	$(RM_F) blib/lib/Xmldoom/Object/Attribute.pm blib/lib/Xmldoom/ORB/Definition/JSON.pm blib/lib/Xmldoom/Criteria/Literal.pm blib/lib/Xmldoom/Definition.pm blib/lib/Xmldoom/ORB/Transport/JSON.pm
	$(RM_F) blib/lib/SQL/Translator/Parser/XML/Propel.pm blib/lib/Xmldoom/Object/Property.pm


# --- MakeMaker metafile section:
metafile:
	$(NOECHO) $(NOOP)


# --- MakeMaker metafile_addtomanifest section:
metafile_addtomanifest:
	$(NOECHO) $(NOOP)


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ *.orig */*~ */*.orig



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(PERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	-e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';'

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker distdir section:
distdir : metafile metafile_addtomanifest
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"



# --- MakeMaker dist_test section:

disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)


# --- MakeMaker dist_ci section:

ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \
	  -e "@all = keys %{ maniread() };" \
	  -e "print(qq{Executing $(CI) @all\n}); system(qq{$(CI) @all});" \
	  -e "print(qq{Executing $(RCS_LABEL) ...\n}); system(qq{$(RCS_LABEL) @all});"


# --- MakeMaker install section:

install :: all pure_install doc_install

install_perl :: all pure_perl_install doc_perl_install

install_site :: all pure_site_install doc_site_install

install_vendor :: all pure_vendor_install doc_vendor_install

pure_install :: pure_$(INSTALLDIRS)_install

doc_install :: doc_$(INSTALLDIRS)_install

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLARCHLIB)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLARCHLIB) \
		$(INST_BIN) $(DESTINSTALLBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLSITELIB) \
		$(INST_ARCHLIB) $(DESTINSTALLSITEARCH) \
		$(INST_BIN) $(DESTINSTALLSITEBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLSITEMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

pure_vendor_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLVENDORARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLVENDORARCH) \
		$(INST_BIN) $(DESTINSTALLVENDORBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLVENDORMAN3DIR)

doc_perl_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_site_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_vendor_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod


uninstall :: uninstall_from_$(INSTALLDIRS)dirs

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE:
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:

# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	-$(MAKE) -f $(MAKEFILE_OLD) clean $(DEV_NULL) || $(NOOP)
	$(PERLRUN) Makefile.PL "dist"
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the make command.  <=="
	false



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /usr/bin/perl5.8.7

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) -f $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE)
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS= \
		dist


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = 
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE)

test_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-Iinc" "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

testdb_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-Iinc" "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

test_ : test_dynamic

test_static :: test_dynamic
testdb_static :: testdb_dynamic


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="$(DISTNAME)" VERSION="0,0,16,0">' > $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <TITLE>$(DISTNAME)</TITLE>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>Xmldoom is a framework that allows you to bind database tables to Perl objects, a technique commonly referred to as object persistence, similar in purpose to Propel and Apache Torque</ABSTRACT>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>David Snopek</AUTHOR>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Callback" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Carp" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="DBD-SQLite" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="DBIx-Romani" VERSION="0,0,16,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Data-Dumper" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Date-Calc" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Exception-Class" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Exception-Class-DBI" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Exception-Class-TryCatch" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="ExtUtils-MakeMaker" VERSION="6,11,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Getopt-Long" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="IO-File" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Module-Runtime" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Module-Util" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="POSIX-strptime" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="SQL-Translator" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Scalar-Util" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Test-Class" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="Test-More" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="XML-DOM" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="XML-GDOME" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="XML-SAX" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="XML-SAX-ExpatXS" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="XML-Writer" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="XML-Writer-String" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <OS NAME="$(OSNAME)" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="i686-linux" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> $(DISTNAME).ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib: $(TO_INST_PM)
	$(NOECHO) $(PERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', '\''$(PM_FILTER)'\'')'\
	  lib/Xmldoom/Definition/LinkTree.pm blib/lib/Xmldoom/Definition/LinkTree.pm \
	  lib/Xmldoom/Definition/PerlModuleParser.pm blib/lib/Xmldoom/Definition/PerlModuleParser.pm \
	  lib/Xmldoom/Definition/Link.pm blib/lib/Xmldoom/Definition/Link.pm \
	  lib/Xmldoom/Criteria/XML.pm blib/lib/Xmldoom/Criteria/XML.pm \
	  lib/SQL/Translator/Producer/XML/Torque.pm blib/lib/SQL/Translator/Producer/XML/Torque.pm \
	  lib/Xmldoom/Criteria/Property.pm blib/lib/Xmldoom/Criteria/Property.pm \
	  lib/Xmldoom/ResultSet.pm blib/lib/Xmldoom/ResultSet.pm \
	  lib/Xmldoom/Threads.pm blib/lib/Xmldoom/Threads.pm \
	  lib/SQL/Translator/Producer/XML/Propel.pm blib/lib/SQL/Translator/Producer/XML/Propel.pm \
	  lib/Xmldoom/Schema/Table.pm blib/lib/Xmldoom/Schema/Table.pm \
	  lib/Xmldoom/Schema/SAXHandler.pm blib/lib/Xmldoom/Schema/SAXHandler.pm \
	  lib/SQL/Translator/Parser/XML/Propel.pm blib/lib/SQL/Translator/Parser/XML/Propel.pm \
	  lib/Xmldoom/Criteria/Search.pm blib/lib/Xmldoom/Criteria/Search.pm \
	  lib/Xmldoom/Definition/Property.pm blib/lib/Xmldoom/Definition/Property.pm \
	  lib/Xmldoom/Object/LinkAttribute.pm blib/lib/Xmldoom/Object/LinkAttribute.pm \
	  lib/Xmldoom/Object/Attribute.pm blib/lib/Xmldoom/Object/Attribute.pm \
	  lib/Xmldoom/Criteria/Comparison.pm blib/lib/Xmldoom/Criteria/Comparison.pm \
	  lib/Xmldoom/Schema/ForeignKey.pm blib/lib/Xmldoom/Schema/ForeignKey.pm \
	  lib/Xmldoom/Criteria/ExplicitJoinVisitor.pm blib/lib/Xmldoom/Criteria/ExplicitJoinVisitor.pm \
	  lib/Xmldoom/Definition/Object.pm blib/lib/Xmldoom/Definition/Object.pm \
	  lib/Thread/Shared/Array.pm blib/lib/Thread/Shared/Array.pm \
	  lib/Xmldoom/Definition/SAXHandler.pm blib/lib/Xmldoom/Definition/SAXHandler.pm \
	  lib/Xmldoom/Criteria/UnknownObject.pm blib/lib/Xmldoom/Criteria/UnknownObject.pm \
	  lib/Xmldoom/Schema.pm blib/lib/Xmldoom/Schema.pm \
	  lib/Xmldoom/Definition/Property/Simple.pm blib/lib/Xmldoom/Definition/Property/Simple.pm \
	  lib/Xmldoom/Definition/Property/PlaceHolder.pm blib/lib/Xmldoom/Definition/Property/PlaceHolder.pm \
	  lib/Thread/Shared/Hash.pm blib/lib/Thread/Shared/Hash.pm \
	  lib/Xmldoom/Schema/Parser.pm blib/lib/Xmldoom/Schema/Parser.pm \
	  lib/Xmldoom/ORB/Definition/JSON.pm blib/lib/Xmldoom/ORB/Definition/JSON.pm \
	  lib/Xmldoom/Schema/Column.pm blib/lib/Xmldoom/Schema/Column.pm \
	  lib/Xmldoom/Criteria.pm blib/lib/Xmldoom/Criteria.pm \
	  lib/SQL/Translator/Parser/XML/Torque.pm blib/lib/SQL/Translator/Parser/XML/Torque.pm \
	  lib/Xmldoom/Object/Property.pm blib/lib/Xmldoom/Object/Property.pm \
	  lib/SQL/Translator/Producer/XML/Xmldoom.pm blib/lib/SQL/Translator/Producer/XML/Xmldoom.pm \
	  lib/SQL/Translator/Parser/XML/Xmldoom.pm blib/lib/SQL/Translator/Parser/XML/Xmldoom.pm \
	  lib/Xmldoom/Definition/Database.pm blib/lib/Xmldoom/Definition/Database.pm \
	  lib/Xmldoom/ORB/Transport.pm blib/lib/Xmldoom/ORB/Transport.pm \
	  lib/Xmldoom/ORB/Transport/JSON.pm blib/lib/Xmldoom/ORB/Transport/JSON.pm \
	  lib/Xmldoom/Definition/Property/Object.pm blib/lib/Xmldoom/Definition/Property/Object.pm \
	  lib/Xmldoom/ORB/Apache.pm blib/lib/Xmldoom/ORB/Apache.pm \
	  lib/Xmldoom/Criteria/Literal.pm blib/lib/Xmldoom/Criteria/Literal.pm \
	  lib/Xmldoom/Object.pm blib/lib/Xmldoom/Object.pm \
	  lib/Xmldoom/Criteria/Attribute.pm blib/lib/Xmldoom/Criteria/Attribute.pm \
	  lib/Xmldoom.pm blib/lib/Xmldoom.pm \
	  lib/Xmldoom/ORB/Definition.pm blib/lib/Xmldoom/ORB/Definition.pm \
	  lib/Xmldoom/Object/XMLGenerator.pm blib/lib/Xmldoom/Object/XMLGenerator.pm \
	  lib/Thread/Shared.pm blib/lib/Thread/Shared.pm \
	  lib/Xmldoom/Definition.pm blib/lib/Xmldoom/Definition.pm \
	  lib/Xmldoom/ORB/Transport/XML.pm blib/lib/Xmldoom/ORB/Transport/XML.pm 
	$(NOECHO) $(TOUCH) $@

# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:


# End.
# Postamble by Module::Install 0.62
# --- Module::Install::Admin::Makefile section:

realclean purge ::
	$(RM_F) $(DISTVNAME).tar$(SUFFIX)
	$(RM_RF) inc MANIFEST.bak _build
	$(PERL) -I. -MModule::Install::Admin -e "remove_meta()"

reset :: purge

upload :: test dist
	cpan-upload -verbose $(DISTVNAME).tar$(SUFFIX)

grok ::
	perldoc Module::Install

distsign ::
	cpansign -s

config ::
	$(NOECHO) $(MOD_INSTALL) \
		"share" $(INST_AUTODIR)

