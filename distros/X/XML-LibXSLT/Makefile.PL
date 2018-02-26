# -------------------------------------------------------------------------- #
# $Id$
# -------------------------------------------------------------------------- #
# Makefile.PL for XML::LibXML.
# This file is required to generate a localized Makefile
# -------------------------------------------------------------------------- #

use strict;
use warnings;

use vars qw/$DEVNULL $is_Win32/;

BEGIN {
  if ($] < 5.008_001) {
    warn "\nSorry, at least Perl 5.8.1 is required for this module!\n\n";
    exit;
  }
}

use ExtUtils::MakeMaker;
use Config;


$|=0;

my %config;

while($_ = shift) {
    my ($key, $val) = split(/=/, $_, 2);
    $config{$key} = $val;
}

my $DEBUG = delete $config{DEBUG};

if ( $] < 5.008 or $config{NO_THREADS} ) {
  warn "disabling XML::LibXML support for Perl threads\n";
  $config{DEFINE} .= " -DNO_XML_LIBXML_THREADS";
}
delete $config{NO_THREADS};

# We use it several times later. See:
# https://rt.cpan.org/Public/Bug/Display.html?id=116461
my $HAVE_USER_DEFINED = (defined($config{LIBS}) or defined($config{INC}) );

unless ( $::is_Win32 ) { # cannot get config in W32
    my $xsltcfg = "xslt-config";
    my $libprefix = $ENV{XSLTPREFIX} || $config{XSLTPREFIX};

    delete $config{XSLTPREFIX}; # delete if exists, otherwise MakeMaker gets confused

    if ( defined $libprefix ) {
        $xsltcfg = $libprefix . '/bin/' . $xsltcfg;
    }

    # if a user defined INC and LIBS on the command line we must not
    # override them
    if ( ! $HAVE_USER_DEFINED ) {
        # get libs and inc from gnome-config
        eval {
            print "running xslt-config... ";
            my $ver = backtick("$xsltcfg --version");
            my ($major, $minor, $point) = $ver =~ /(\d+)\.(\d+)\.(\d+)/g;
            if (not
                (
                    ($major > 1)
                        or
                    (($major == 1) && ($minor > 1))
                        or
                    (($major == 1) && ($minor == 1) && ($point >= 18))
                )
            )
            {
                die +{ type => "ver", msg => <<'EOF'};
libxslt versions before 1.1.18 are buggy. Please install the latest version
EOF
            }
            elsif ($major == 1 and $minor == 1 and $point == 25)
            {
                die +{ type => "ver", msg => <<'EOF'};
libxslt-1.1.25 contains a deadlock that breaks the tests, and is not supported.
See: https://rt.cpan.org/Ticket/Display.html?id=50487 .
EOF
            }
            elsif ($major == 1 and $minor == 1 and $point == 27)
            {
                die +{ type => "ver", msg => <<'EOF'};
libxslt-1.1.27 does not handle namespaces well, and is not supported.
See: https://bugzilla.gnome.org/show_bug.cgi?id=684564 .
EOF
            }

            $config{LIBS} ||= backtick("$xsltcfg --libs");
            $config{INC} ||= backtick("$xsltcfg --cflags");
            print "ok\n";
        };
        my $Err = $@;
        if ($Err) {
            print "failed\n";
            if ((ref($Err) eq 'HASH') && (($Err->{type} || '') eq 'ver')) {
                print {*STDERR} ($Err->{msg}, "\n");
                exit 0; # 0 recommended by http://cpantest.grango.org (Notes for CPAN Authors)
            }
            warn "*** ", $@ if $DEBUG;
            warn "using fallback values for LIBS and INC\n";
            # backtick fails if gnome-config didn't exist...
            $config{LIBS} = '-L/usr/local/lib -L/usr/lib -lxslt -lxml2 -lz -lm';
            $config{INC} = '-I/usr/local/include -I/usr/include';

            print <<OPT;
options:
  LIBS='$config{LIBS}'
  INC='$config{INC}'
If this is wrong, Re-run as:
  \$ $^X Makefile.PL LIBS='-L/path/to/lib' INC='-I/path/to/include'

OPT
        }
    }
}

if ($config{LIBS} !~ /\-l(lib)?xslt\b/) {
    # in this case we are not able to run xml2-config. therefore we need to
    # expand the libz as well.
  if ($::is_Win32) {
    if( $ENV{ACTIVEPERL_MINGW} ) {
      $config{LIBS} .= ' -llibxslt.lib -llibxml2.lib';
    } else {
      $config{LIBS} .= ' -llibxslt -llibxml2';
    }
  } else {
    $config{LIBS} .= ' -lxml2 -lz';
  }
}

if ($config{LIBS} !~ /\-lz(lib)?\b/ and !($::is_Win32 && $config{LIBS} !~ /\-lzlib\b/)) {
    # note if libxml2 has not -lz within its cflags, we should not use
    # it! We should trust libxml2 and assume libz is not available on the
    # current system (this is ofcourse not true with win32 systems.
    # $config{LIBS} .= $::is_Win32 ? ' -lzlib' :' -lz';
    if ( $config{DEBUG} ) {
        warn "zlib was not configured\n";
        warn "set zlib\n" if $::is_Win32;
    }
  if ($::is_Win32) {
    if( $ENV{ACTIVEPERL_MINGW} ) {
      $config{LIBS} .= '';
    } else {
      $config{LIBS} .= ' -lzlib';
    }
  } else {
    $config{LIBS} .= ' -lz';
  }
}

if ($config{LIBS} !~ /\-lm\b/) {
    # math support is important, but is not available separately in W32
    $config{LIBS} .= $::is_Win32 ? '' :' -lm';
}

if (!have_library($::is_Win32 ? "libxslt" : "xslt")) {
    print STDERR <<DEATH;
libxslt not found
Try setting LIBS and INC values on the command line
Or get libxslt and libxml2 from
  http://www.libxml.org/
If you install via RPMs, make sure you also install the -devel
RPMs, as this is where the headers (.h files) are.
DEATH
exit 0; # 0 recommended by http://cpantest.grango.org (Notes for CPAN Authors)
}


if (have_library($::is_Win32 ? "libexslt" : "exslt")) {
    if (! $HAVE_USER_DEFINED) {
        my $exslt_defaults = $::is_Win32 ?
        ($ENV{ACTIVEPERL_MINGW} ? q/-llibexslt.lib/ : q/-llibexslt/) :
        q/-lexslt/; # -lgcrypt -lgpg-error/;
        my $exsltcfg = 'pkg-config libexslt';
        my ($exslt_libs,$exslt_inc);
        eval {
            print "running $exsltcfg... ";
            $exslt_libs = backtick("$exsltcfg --libs");
            $exslt_inc = backtick("$exsltcfg --cflags");
            $exslt_libs =~ s/-l(xml2|xslt|z|m)\s+//g;
            print "ok\n";
        };
        if ($@) {
            print "failed\n";
            warn "*** ", $@ if $DEBUG;
            warn "using fallback values for LIBS and INC\n";
            # backtick fails if gnome-config didn't exist...
            $exslt_libs  = $exslt_defaults;
            $exslt_inc   = '';
        }
        $config{LIBS} .= ' '.$exslt_libs;
        $config{INC} .= ' '.$exslt_inc;
    }
    $config{DEFINE} .= " -DHAVE_EXSLT"
}

if ($DEBUG) {
  print "LIBS: $config{LIBS}\n";
  print "INC: $config{INC}\n";
}

my $ldflags = delete $config{LDFLAGS};
if ($ldflags) {
    $config{dynamic_lib} = { OTHERLDFLAGS => " $ldflags " };
}

# Avoid possible shared library name conflict. On Win32 systems
# the name of system DLL libxlst.dll clashes with module's LibXSLT.dll.
# To handle this we are gonna rename module's DLL to LibXSLT.xs.dll.
if ($::is_Win32)
{
    if ($] eq '5.010000')
    {
        print STDERR <<'BUG';
******************************** !!!WARNING!!! ********************************
According to the version string you are running a win32 perl 5.10.0 that is
known to be suffering from dynaloader bug that prevents using non-default
module's DLL name. Therefore we have to use LibXSLT.dll that will clash with the
standard name of xslt library DLL. Please consider renaming your xslt library
to e.g. libxslt_win32.dll and then make the appropriate changes to this module's
build process to look for that instead of standard libxslt.dll. If you do not
make the proposed changes you will got during the tests many error popups with
slightly confusing message about "xsltApplyOneTemplate" function.
This bug is not present in perl 5.8.* and will be fixed in 5.10.1.
*******************************************************************************
BUG
    }
    else
    {
        # Fix for RT #94516 :
        # https://rt.cpan.org/Ticket/Display.html?id=94516
        $config{DLEXT} = 'xs.'.$Config{dlext};
    }
}

WriteMakefile(
    'NAME'	=> 'XML::LibXSLT',
    'VERSION_FROM' => 'LibXSLT.pm', # finds $VERSION
    'AUTHOR'    => 'Matt Sergeant',
    'ABSTRACT'  => 'Interface to GNOME libxslt library',
    'LICENSE'   => 'perl_5',
    'PREREQ_PM' =>
    {
        'Encode' => 0,
        'XML::LibXML' => "1.70",
        'strict' => 0,
        'warnings' => 0,
    },
    'OBJECT'     => '$(O_FILES)',
    (($ExtUtils::MakeMaker::VERSION >= 6.48)
        ? (MIN_PERL_VERSION => '5.008001',)
        : ()
    ),
    'META_MERGE' => {
        'meta-spec' => {
            'version' => 2,
        },
        'resources' => {
            'repository' => {
                'type' => 'git',
                'url'  => 'https://github.com/shlomif/perl-XML-LibXSLT',
                'web'  => 'https://github.com/shlomif/perl-XML-LibXSLT',
            },
        },
    },
    %config,
);

###################################################################
# Functions
#  - these should really be in MakeMaker... But &shrug;
###################################################################

use Config;
use Cwd;
use Symbol;
use File::Spec;


BEGIN {
    $::is_Win32 = ($^O =~ /Win32/);
    if ($::is_Win32) {
        $DEVNULL = 'DEVNULL';
    }
    else {
        $DEVNULL = eval { File::Spec->devnull };
        if ($@) { $DEVNULL = '/dev/null' }
    }
}

sub rm_f {
    my @files = @_;
    my @realfiles;
    foreach (@files) {
        push @realfiles, glob($_);
    }
    if (@realfiles) {
        chmod(0777, @realfiles);
        unlink(@realfiles);
    }
}

sub rm_fr {
    my @files = @_;
    my @realfiles;
    foreach (@files) {
        push @realfiles, glob($_);
    }
    foreach my $file (@realfiles) {
        if (-d $file) {
            # warn("$file is a directory\n");
            rm_fr("$file/*");
            rm_fr("$file/.exists");
            rmdir($file) || die "Couldn't remove $file: $!";
        }
        else {
            # warn("removing $file\n");
            chmod(0777, $file);
            unlink($file);
        }
    }
}

sub xsystem {
  my (@command)=@_;
    if ($DEBUG) {
        print "@command\n";
        if (system(@command) != 0) {
            die "system call to '@command' failed";
        }
        return 1;
    }
    open(OLDOUT, ">&STDOUT");
    open(OLDERR, ">&STDERR");
    open(STDOUT, ">$DEVNULL");
    open(STDERR, ">$DEVNULL");
    my $retval = system(@command);
    open(STDOUT, ">&OLDOUT");
    open(STDERR, ">&OLDERR");
    if ($retval != 0) {
        die "system call to '@command' failed";
    }
    return 1;
}

sub backtick {
    my $command = shift;
    if ($DEBUG) {
        print $command, "\n";
        my $results = `$command`;
        chomp $results;
        if ($? != 0) {
            die "backticks call to '$command' failed";
        }
        return $results;
    }
    open(OLDOUT, ">&STDOUT");
    open(OLDERR, ">&STDERR");
    open(STDOUT, ">$DEVNULL");
    open(STDERR, ">$DEVNULL");
    my $results = `$command`;
    my $retval = $?;
    open(STDOUT, ">&OLDOUT");
    open(STDERR, ">&OLDERR");
    if ($retval != 0) {
        die "backticks call to '$command' failed";
    }
    chomp $results;
    return $results;
}

sub try_link0 {
    my ($src, $opt) = @_;
    my $cfile = gensym();
    # local $config{LIBS};
    # $config{LIBS} .= $opt;
    unless (mkdir(".testlink", 0777)) {
        rm_fr(".testlink");
        mkdir(".testlink", 0777) || die "Cannot create .testlink dir: $!";
    }
    chdir(".testlink");
    open($cfile, ">Conftest.xs") || die "Cannot write to file Conftest.xs: $!";
print $cfile <<EOT;
#ifdef __cplusplus
extern "C" {
#endif
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#ifdef __cplusplus
}
#endif

EOT
    print $cfile $src;
    print $cfile <<EOT;

MODULE = Conftest          PACKAGE = Conftest

PROTOTYPES: DISABLE

EOT
    close($cfile);
    open($cfile, ">Conftest.pm") || die "Cannot write to file Conftest.pm: $!";
    print $cfile <<'EOT';
package Conftest;
$VERSION = 1.0;
require DynaLoader;
@ISA = ('DynaLoader');
bootstrap Conftest $VERSION;
1;
EOT
    close($cfile);
    open($cfile, ">Makefile.PL") || die "Cannot write to file Makefile.PL: $!";
    print $cfile <<'EOT';
use ExtUtils::MakeMaker;
my %config;
while($_ = shift @ARGV) {
    my ($k, $v) = split /=/, $_, 2;
    warn("$k = $v\n");
    $config{$k} = $v;
}
WriteMakefile(NAME => "Conftest", VERSION_FROM => "Conftest.pm", %config);
EOT
    close($cfile);
    open($cfile, ">test.pl") || die "Cannot write to file test.pl: $!";
    print $cfile <<EOT;
use Test; BEGIN { plan tests => 1; } END { ok(\$loaded) }
use Conftest; \$loaded++;
EOT
    close($cfile);
    xsystem($^X,'Makefile.PL',map "$_=$config{$_}", keys %config);
    xsystem($Config{make},
	    ($config{MAKEAPERL} ? qw(-f Makefile.aperl FIRST_MAKEFILE=Makefile.aperl) : ()),
	    'test'); #,"OTHERLDFLAGS=".$opt);
}

sub try_link {
    my $start_dir = cwd();
    my $result = eval {
        try_link0(@_);
    };
    warn $@ if $DEBUG && $@;
    chdir($start_dir);
    rm_fr(".testlink");
    return $result;
}

sub have_library {
    my ($lib, $func) = (@_, "blank");
    printf("checking for %s() in -l%s... ", $func, $lib) if $func ne "blank";
    printf("looking for -l%s... ", $lib) if $func eq "blank";

    my $result;
    if ($func) {
        my $libs = $::is_Win32 ? " $lib.lib  " : "-l$lib";
        if ($::is_Win32) {
            $result = try_link(<<"SRC", $libs);
#include <windows.h>
#include <winsock.h>
blank() { return 0; }
int t() { ${func}(); return 0; }
SRC
            unless ($result) {
                $result = try_link(<<"SRC", $libs);
#include <windows.h>
#include <winsock.h>
blank() { return 0; }
int t() { void ((*p)()); p = (void ((*)()))${func}; return 0; }
SRC
            }
        }
        else {

            $result = try_link(<<"SRC", $libs);
blank() { return 0; }
int t() { ${func}(); return 0; }
SRC
        }
    }

    unless ($result) {
        print "no\n";
        return 0;
    }

    if ($func ne "main") {
        $config{DEFINE} .= uc(" -Dhave_$func");
    }

    print "yes\n";
    return 1;
}

sub MY::postamble {
  return <<'MAKE_FRAG';

runtest: pure_all
	perl -MFile::Spec -MTest::Run::CmdLine::Iface -e \
        "local @INC = @INC;	unshift @INC, map { File::Spec->rel2abs(\$$_) } ('$(INST_LIB)', '$(INST_ARCHLIB)'); Test::Run::CmdLine::Iface->new({test_files => [glob(q{t/*.t})]})->run();"

distruntest: distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) runtest $(PASTHRU)

MAKE_FRAG
}

