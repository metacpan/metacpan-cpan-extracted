# $Id: Makefile.PL,v 1.40 2006/08/11 13:19:52 jeff Exp $

# Makefile generator for extproc_perl

use Config;
use Cwd;

my $build_dir = getcwd();

print "Verifying configuration...\n\n";

# make sure we've set ORACLE_HOME
my $oracle_home = $ENV{'ORACLE_HOME'};
unless ($oracle_home) {
	die "Please set the ORACLE_HOME environment variable.";
}

# verify we have a shared libperl
if ($Config{'useshrplib'} ne 'yes' && $Config{'useshrplib'} ne 'true') {
	die "A shared libperl is required to build this distribution."
} 
print "You are using a shared libperl.  Good.\n";

# verify we are NOT using a threads-enabled perl
if ($Config{'usethreads'} eq 'define') {
	die "Threads-enabled Perl is not supported in this version.";
}
print "You are not using a threads-enabled Perl.  Good.\n";

# verify Parse::RecDescent install
eval 'use Parse::RecDescent';
die "Could not find Parse::RecDescent.  Please install it, then re-run Makefile.PL.\n" if $@;

# what is the path to perl?
my $perl = $Config{'perlpath'};

# what version are we using?
my $perl_version = $Config{'version'};

# what is the extension for shared libraries?
my $dlext = $Config{'dlext'};

# where to install scripts
my $script_bin = $Config{'installscript'};

# set some defaults
$DEFAULT_USER = "oracle";
$DEFAULT_GROUP = "dba";
$DEFAULT_MODS = "IO Socket attrs Fcntl DBI DBD::Oracle";
$DEFAULT_INST_PATH = "$oracle_home/lib";
$DEFAULT_CONFIG_DIR = "$oracle_home";
$DEFAULT_BOOTSTRAP = "$oracle_home/perl/extproc_perl_boot.pl";
$DEFAULT_CODE_TABLE = "user_perl_source";
$DEFAULT_TRUSTED_DIR = "$oracle_home/perl/src";

# load config from previous run
if ( -r '.config' ) {
	eval { require '.config'; };
	print STDERR "Using cached configuration.\n";
}
else {
	print STDERR "No cached configuration.  Starting from scratch.\n";
}

print "\nAs what user do external procedures run? [$DEFAULT_USER]? ";
my $ora_user = <STDIN>;
chomp $ora_user;
unless ($ora_user) {
	$ora_user = $DEFAULT_USER;
}

print "What is the Oracle group? [$DEFAULT_GROUP]? ";
my $ora_group = <STDIN>;
chomp $ora_group;
unless ($ora_group) {
	$ora_group = $DEFAULT_GROUP;
}

print <<_DONE_;

Oracle does not support Perl's dynamic loading of modules, so you need to
specify at compile time which modules you want to use.  This does not apply
to Perl-only modules, but you can enter them here anyway if you are unsure,
and they will be ignored.  ExtProc is automatically included, so you don't
need to specify it here.  Type "+" first if you want to add to the default
list instead of replacing it (e.g. "+Authen::Krb5 HTML::Parser").  Remember,
you can always update this list and relink later.

_DONE_

print "Modules to include in this build [$DEFAULT_MODS]: ";
my $mods = <STDIN>;
chomp $mods;
unless ($mods) {
	$mods = $DEFAULT_MODS;
}
if ($mods =~ /^\+(.*)/) {
	$mods = "$DEFAULT_MODS $1";
}

print <<_DONE_;

NOTE: If you are using Oracle 9.2.0 or higher, external procedure libraries
must must be located in \$ORACLE_HOME/lib or else you will need include the
path to the each library in the EXTPROC_DLLS environment variable for your
listener.  Failure to do this will result in an ORA-28595 error.  See Oracle
documentation for details.

_DONE_
print "Where should I install the extproc_perl libraries [$DEFAULT_INST_PATH]? ";
my $instpath = <STDIN>;
chomp $instpath;
unless ($instpath) {
	$instpath = $DEFAULT_INST_PATH;
}

print "Where should I install the extproc_perl configuration file [$DEFAULT_CONFIG_DIR]? ";
my $confdir = <STDIN>;
chomp $confdir;
unless ($confdir) {
	$confdir = $DEFAULT_CONFIG_DIR;
}

print <<_DONE_;

extproc_perl can parse a global bootstrap file that contains Perl code shared
by all sessions.  You can use it to store common subroutines or data, even
system-specific data, as it lives in the file system rather than the database.
If you do not want this feature enabled at all, type 'none' (without the
quotes).

_DONE_

print "Path to bootstrap file [$DEFAULT_BOOTSTRAP]: ";
my $bootfile = <STDIN>;
chomp $bootfile;
unless ($bootfile) {
	$bootfile = $DEFAULT_BOOTSTRAP;
}
else {
	$bootfile = "" if $bootfile eq "none";
}

print <<_DONE_;

extproc_perl will query the calling database for a Perl subroutine if it
doesn't exist in the bootstrap file.  Specify the default table to query here.

_DONE_

print "Table to query [${DEFAULT_CODE_TABLE}]: ";
my $code_table = <STDIN>;
chomp $code_table;
unless ($code_table) {
	$code_table = $DEFAULT_CODE_TABLE;
}

print <<_DONE_;

You can import code into the database from various files.  For security, these
files will only be imported from one directory, called the "trusted code
directory".

_DONE_

print "What is the path to this directory? [${DEFAULT_TRUSTED_DIR}]: ";
my $trusted_dir = <STDIN>;
chomp $trusted_dir;
unless ($trusted_dir) {
	$trusted_dir = $DEFAULT_TRUSTED_DIR;
}

print "\nWriting configuration cache...\n";
open(FILE, ">.config") or die $!;
print FILE qq{
\$DEFAULT_USER = '$ora_user';
\$DEFAULT_GROUP = '$ora_group';
\$DEFAULT_MODS = '$mods';
\$DEFAULT_INST_PATH = '$instpath';
\$DEFAULT_CONFIG_DIR = '$confdir';
\$DEFAULT_BOOTSTRAP = '$bootfile';
\$DEFAULT_CODE_TABLE = '$code_table';
\$DEFAULT_TRUSTED_DIR = '$trusted_dir';
};
close(FILE);

my $CC = $Config{'cc'};
my $LD = $Config{'ld'};
my $LDDLFLAGS = $Config{'lddlflags'};
my $OPT = $Config{'optimize'};
my $CCCDLFLAGS = $Config{'cccdlflags'};
my $RFLAG = ($Config{'archname'} =~ /solaris/) ? '-R' : '-Wl,-rpath,';

print "\nGenerating perlxsi.mk...\n";
open(FILE,">perlxsi.mk") or die "couldn't open perlxsi.mk for writing: $!";
print FILE <<_DONE_;
# Edit the MODULES variable to configure the modules available from extproc_perl
MODULES=ExtProc ${mods}

### DO NOT EDIT BELOW THIS LINE ###

CC=${CC}
LD=${LD}
OPT=${OPT}
CCCDLFLAGS=${CCCDLFLAGS}
RFLAG=${RFLAG}
PERL=${perl}
ORACLE_HOME=${oracle_home}
CPPFLAGS=-I. -I\$(ORACLE_HOME)/rdbms/demo -I\$(ORACLE_HOME)/rdbms/public
INST_DIR=${instpath}
ORA_USER=${ora_user}
ORA_GROUP=${ora_group}

all: libperlxsi.${dlext}

perlxsi.c:
	\$(PERL) -MExtUtils::Embed -e xsinit -- -o STDOUT -std \$(MODULES) | grep -v boot_DynaLoader > \$@

.c.o: extproc_perl.h
	# need -o argument to keep the path intact from the original source
	\$(CC) -o \$*.o \$(CPPFLAGS) `\$(PERL) -MExtUtils::Embed -e ccopts` \$(OPT) \$(CCCDLFLAGS) -c \$<

all: libperlxsi.${dlext}

libperlxsi.${dlext}: perlxsi.o \$(INST_DIR)/libExtProc.${dlext}
	[ -f "\$@" ] && mv \$@ \$@.old
	\$(LD) -o \$@ `\$(PERL) -MExtUtils::Embed -e ldopts` ${LDDLFLAGS} perlxsi.o `\$(PERL) gen_module_libs \$(MODULES)` -L\$(INST_DIR) \$(RFLAG)\$(INST_DIR) -lExtProc
	rm -f perlxsi.c perlxsi.o

libperlxsi_test.${dlext}: perlxsi.o ${build_dir}/libExtProc.${dlext}
	\$(LD) -o \$@ `\$(PERL) -MExtUtils::Embed -e ldopts` ${LDDLFLAGS} perlxsi.o `\$(PERL) gen_module_libs \$(MODULES)` -L${build_dir} \$(RFLAG)${build_dir} -lExtProc

test: libperlxsi_test.${dlext}
_DONE_
close(FILE);

print "\nWriting Makefile...\n";

rename("Makefile","Makefile.old");
open(FILE,">Makefile") or die "couldn't open Makefile for writing: $!";
print FILE <<_DONE_;
# AUTO-GENERATED BY Makefile.PL -- DO NOT EDIT!

CC=${CC}
LD=${LD}
OPT=${OPT}
CCCDLFLAGS=${CCCDLFLAGS}
RFLAG=${RFLAG}
PERL=${perl}
INSTALL=./install-sh
ORACLE_HOME=${oracle_home}
MODULES=ExtProc ${mods}
CPPFLAGS=-I. -I\$(ORACLE_HOME)/rdbms/demo -I\$(ORACLE_HOME)/rdbms/public -DPERL_VERSION_STRING=\\"${perl_version}\\" -DBOOTSTRAP_FILE=\\"${bootfile}\\" -DCODE_TABLE=\\"${code_table}\\" -DSTATIC_MODULES="\\"\$(MODULES)\\"" -DEP_CONFIG_FILE="\\"${confdir}/extproc_perl.conf\\"" -DBUILD_DIR=\\"${build_dir}\\"

OBJS=extproc_perl.o oci.o config.o wrapper.o
TESTOBJS=testcode.o
XSIOBJS=perlxsi.o
CONFS=extproc_perl.conf ep_package.sql ep_schema.sql ep_upgrade.sql

all: extproc_perl.${dlext} \$(CONFS)

extproc_perl.conf: extproc_perl.conf.in
	\$(PERL) -p -e 's%-BOOTSTRAP-%$bootfile%g; s%-CODETABLE-%$code_table%g; s%-INSTPATH-%$instpath%g; s%-TRUSTEDDIR-%$trusted_dir%g;' extproc_perl.conf.in > \$@

ep_package.sql: ep_package.sql.in
	\$(PERL) -p -e 's%-BOOTSTRAP-%$bootfile%g; s%-CODETABLE-%$code_table%g; s%-INSTPATH-%$instpath%g;' ep_package.sql.in > \$@

ep_schema.sql: ep_schema.sql.in
	\$(PERL) -p -e 's%-BOOTSTRAP-%$bootfile%g; s%-CODETABLE-%$code_table%g; s%-INSTPATH-%$instpath%g;' ep_schema.sql.in > \$@

ep_upgrade.sql: ep_upgrade.sql.in
	\$(PERL) -p -e 's%-CODETABLE-%$code_table%g;' ep_upgrade.sql.in > \$@

perlxsi.c:
	\$(PERL) -MExtUtils::Embed -e xsinit -- -o STDOUT -std \$(MODULES) | grep -v boot_DynaLoader > \$@

libExtProc.${dlext}: extproc_perl.h ExtProc/ExtProc.xs
	(cd ExtProc ; \$(MAKE))
	cp -f ExtProc/blib/arch/auto/ExtProc/ExtProc.${dlext} libExtProc.${dlext}

.c.o:
	\$(CC) \$(CPPFLAGS) `\$(PERL) -MExtUtils::Embed -e ccopts` \$(OPT) \$(CCCDLFLAGS) -c \$<

libperlxsi.${dlext}: \$(XSIOBJS) libExtProc.${dlext}
	\$(LD) -o \$@ `\$(PERL) -MExtUtils::Embed -e ldopts` ${LDDLFLAGS} \$(XSIOBJS) `\$(PERL) gen_module_libs \${MODULES}` -L. \$(RFLAG)${instpath} -lExtProc

libperlxsi_test.${dlext}: \$(XSIOBJS) libExtProc.${dlext}
	\$(LD) -o \$@ `\$(PERL) -MExtUtils::Embed -e ldopts` ${LDDLFLAGS} \$(XSIOBJS) `\$(PERL) gen_module_libs \${MODULES}` -L. \$(RFLAG)${build_dir} -lExtProc

extproc_perl.${dlext}: \$(OBJS) libperlxsi.${dlext}
	\$(LD) -o \$@ `\$(PERL) -MExtUtils::Embed -e ldopts` ${LDDLFLAGS} \$(OBJS) -L. ${RFLAG}${trusted_dir} libperlxsi.${dlext}

extproc_perl_test.${dlext}: \$(OBJS) \$(TESTOBJS) libperlxsi_test.${dlext}
	\$(LD) -o \$@ `\$(PERL) -MExtUtils::Embed -e ldopts` ${LDDLFLAGS} \$(OBJS) \$(TESTOBJS) -L. ${RFLAG}${build_dir} libperlxsi_test.${dlext}

install: all
	\$(INSTALL) -c -m 555 -o ${ora_user} -g ${ora_group} extproc_perl.${dlext} ${instpath}
	\$(INSTALL) -c -m 555 -o ${ora_user} -g ${ora_group} libExtProc.${dlext} ${instpath}
	\$(INSTALL) -d -m 775 -o ${ora_user} -g ${ora_group} ${trusted_dir}
	[ -f ${trusted_dir}/libperlxsi.so ] || \$(INSTALL) -c -m 555 -o ${ora_user} -g ${ora_group} libperlxsi.${dlext} ${trusted_dir}
	\$(INSTALL) -c -m 444 -o ${ora_user} -g ${ora_group} extproc_perl.h ${trusted_dir}
	[ -f ${trusted_dir}/perlxsi.mk ] || \$(INSTALL) -c -m 644 -o ${ora_user} -g ${ora_group} perlxsi.mk ${trusted_dir}
	\$(INSTALL) -c -m 555 -o ${ora_user} -g ${ora_group} gen_module_libs ${trusted_dir}
	[ -f ${confdir}/extproc_perl.conf ] || \$(INSTALL) -c -m 644 -o ${ora_user} -g ${ora_group} extproc_perl.conf ${confdir}
	(cd ExtProc ; \$(MAKE) install)

test: extproc_perl_test.${dlext}
	\$(PERL) test.pl t/*.t

clean:
	rm -f *.o extproc_perl*.${dlext} libperlxsi*.${dlext} libExtProc.${dlext} perlxsi.c perlxsi.mk Makefile \$(CONFS) t/*.c t/*.sql t/*.o
	(cd ExtProc ; \$(MAKE) clean)

distclean: clean
	rm -f Makefile.old .config
	(cd ExtProc ; \$(MAKE) realclean ; rm -f Makefile.old)
_DONE_
close(FILE);

print "Configuring ExtProc module\n";
system("cd ExtProc ; ${perl} Makefile.PL");
print "Done.\n";
