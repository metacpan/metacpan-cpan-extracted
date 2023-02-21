use strict;
use warnings;
use 5.014;

use vars qw/ $DEVNULL $is_Win32 /;

use ExtUtils::MakeMaker;
use Config;
use Cwd qw/ cwd /;
use File::Spec ();
use File::Path 2.06 qw( make_path remove_tree );

BEGIN {
    $::is_Win32 = ($^O =~ /Win32/);
    if ($::is_Win32) {
        $DEVNULL = 'DEVNULL';
    }
    else {
        $DEVNULL = eval { File::Spec->devnull };
        if ($@) { $DEVNULL = '/dev/null' }
    }
};

STDOUT->autoflush(1);

my %config;

while (my $arg = shift(@ARGV)) {
    my ($key, $val) = split(/=/, $arg, 2);
    $config{$key} = $val;
}

my $DEBUG = delete $config{DEBUG};

if ( delete $config{NO_THREADS} ) {
    warn "disabling XML::LibXML support for Perl threads\n";
    $config{DEFINE} .= " -DNO_XML_LIBXML_THREADS";
}

# We use it several times later. See:
# https://rt.cpan.org/Public/Bug/Display.html?id=116461
my $HAVE_USER_DEFINED = (defined($config{LIBS}) or defined($config{INC}) );

unless ( $::is_Win32 ) { # cannot get config in W32
    my $xsltcfg = "pkg-config libxslt";
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
            print "running $xsltcfg... ";
            my $ver = backtick("$xsltcfg --modversion");
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

            ($config{LIBS} ||= '' ) .= backtick("$xsltcfg --libs");
            ($config{INC} ||= '') .= backtick("$xsltcfg --cflags");
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
            ($config{LIBS} ||= '' ) .= ' -L/usr/local/lib -L/usr/lib -lxslt -lxml2 -lz -lm';
            ($config{INC} ||= '') .= ' -I/usr/local/include -I/usr/include';

            print <<"OPT";
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
    print STDERR <<"DEATH";
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
    # Fix for RT #94516 :
    # https://rt.cpan.org/Ticket/Display.html?id=94516
    $config{DLEXT} = 'xs.'.$Config{dlext};
}

WriteMakefile(
    'NAME'	=> 'XML::LibXSLT',
    'VERSION_FROM' => 'lib/XML/LibXSLT.pm', # finds $VERSION
    'AUTHOR'    => 'Matt Sergeant',
    'ABSTRACT'  => 'Interface to GNOME libxslt library',
    'LICENSE'   => 'perl_5',
    'PREREQ_PM' =>
    {
        'Encode' => 0,
        'File::Path' => "2.06",
        'XML::LibXML' => "1.70",
        'strict' => 0,
        'warnings' => 0,
    },
    'OBJECT'     => '$(O_FILES)',
    (($ExtUtils::MakeMaker::VERSION >= 6.52)
        ? (
            'CONFIGURE_REQUIRES' =>
            {
                'File::Path' => "2.06",
                'strict' => 0,
                'warnings' => 0,
            },
        )
        : ()
    ),
    (($ExtUtils::MakeMaker::VERSION >= 6.48)
        ? (MIN_PERL_VERSION => '5.014',)
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

sub _write_utf8_file
{
    my ($out_path, $contents) = @_;

    open my $out_fh, '>:encoding(utf8)', $out_path
        or die "Cannot open '$out_path' for writing - $!";

    print {$out_fh} $contents;

    close($out_fh);

    return;
}

sub _write_raw_file
{
    my ($out_path, $contents) = @_;

    open my $out_fh, '>:raw', $out_path
        or die "Cannot open '$out_path' for writing - $!";

    print {$out_fh} $contents;

    close($out_fh);

    return;
}

sub try_link0 {
    my ($src, $opt) = @_;
    # local $config{LIBS};
    # $config{LIBS} .= $opt;
    unless (mkdir(".testlink", 0777)) {
        remove_tree(".testlink");
        mkdir(".testlink", 0777) || die "Cannot create .testlink dir: $!";
    }
    chdir(".testlink");
    _write_utf8_file("Conftest.xs", <<"EOT");
#ifdef __cplusplus
extern "C" {
#endif
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#ifdef __cplusplus
}
#endif
$src

MODULE = Conftest          PACKAGE = Conftest

PROTOTYPES: DISABLE

EOT

    _write_utf8_file("Conftest.pm", <<'EOT');
package Conftest;
$VERSION = 1.0;
require DynaLoader;
@ISA = ('DynaLoader');
bootstrap Conftest $VERSION;
1;
EOT
_write_utf8_file("Makefile.PL", <<'EOT');
use ExtUtils::MakeMaker;
my %config;
while($_ = shift @ARGV) {
    my ($k, $v) = split /=/, $_, 2;
    warn("$k = $v\n");
    $config{$k} = $v;
}
WriteMakefile(NAME => "Conftest", VERSION_FROM => "Conftest.pm", %config);
EOT
    _write_utf8_file("test.pl", <<"EOT");
use Test::More tests => 1;
use Conftest;
++\$::loaded;
ok(\$::loaded, "loaded") ;
EOT
    xsystem($^X, 'Makefile.PL', map { "$_=$config{$_}" } keys %config);
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
    remove_tree(".testlink");
    return $result;
}

sub have_library {
    my ($lib, $func) = (@_, "blank");
    if ($func eq "blank")
    {
        printf("looking for -l%s... ", $lib);
    }
    else
    {
        printf("checking for %s() in -l%s... ", $func, $lib);
    }

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
            # Use a fake prototype in the style of autoconf.
            $result = try_link(<<"SRC", $libs);
char blank(void) { return 0; }
char ${func}(void);
int t(void) { ${func}(); return 0; }
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
