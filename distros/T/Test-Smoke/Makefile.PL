#! perl -w
use strict;
use v5.10;
use ExtUtils::MakeMaker 6.55_03;
use Config;

my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0 }
use File::Spec::Functions qw( :DEFAULT rel2abs );
use Cwd;
use File::Path;
use Text::ParseWords qw( quotewords shellwords );

# Some strange stuff happens when WriteMakefile() is called
# on a non-clean distribution, cleanup before
if (-f 'Makefile') {
    local *SAVEERR; open SAVEERR, ">&STDERR";
    local *SAVEOUT; open SAVEOUT, ">&STDOUT";
    close STDERR; close STDOUT;

    my $opt = $^O eq 'VMS'
        ? '/IGNORE'
        : $^O eq 'haiku'
            ? ''
            : ' -i';
    system "$Config{make}$opt distclean";

    open STDOUT, ">&SAVEOUT"; close SAVEOUT;
    open STDERR, ">&SAVEERR"; close SAVEERR;
}

my $mmver = eval "ExtUtils::MakeMaker->VERSION";

my $prefix_or_base = 'PREFIX';
if (my $perl_mm_opt = $ENV{PERL_MM_OPT}) {
    my @mm_opts = shellwords($perl_mm_opt);
    my ($install_base) = grep { m<^ INSTALL_BASE= >x } @mm_opts;
    if ($install_base) {
        $prefix_or_base = 'INSTALL_BASE';
        my (undef, $install_path) = quotewords('=', 0, $install_base);
        $ENV{SMOKE_INSTDIR} //= $install_path if $install_path;
    }
}

my %install = ( );
if (!@ARGV and !$ENV{SMOKE_INST_SITE_LIB}) {
    my $dft_install = exists $ENV{SMOKE_INSTDIR} && $ENV{SMOKE_INSTDIR} ne ""
        ? $ENV{SMOKE_INSTDIR}
        : catdir( updir(), 'smoke' );
    $dft_install = rel2abs( $dft_install );

    my $install_dir = $dft_install;
    if (!$ENV{AUTOMATED_TESTING}) {
        # So CPAN.pm will ask for install-directory!
        local $ENV{PERL_MM_USE_DEFAULT};
        $install_dir = dir_prompt(
            "Where would you like to install Test::Smoke?\n",
            $dft_install
        );
    }

    %install = (
        INSTALLSITESCRIPT => $install_dir,
        $prefix_or_base   => $install_dir,
        ($prefix_or_base eq 'PREFIX'
            ? (LIB => "$install_dir/lib")
            : ()
        ),
    );
}
else { # this will be the default in some time
    if (my ($switch) = grep { m{^--site-lib$} } @ARGV) {
        @ARGV = grep { $_ !~ m{^--site-lib$} } @ARGV;
    }
}

my @scripts = qw(
    tssmokestatus.pl tssysinfo.pl
    tssynctree.pl tsrunsmoke.pl tssendrpt.pl tsarchive.pl
    tssmokeperl.pl tsreport.pl tsrepostjsn.pl
    tsw32configure.pl tsconfigsmoke.pl tsarchivelog.pl
);
my @pod_scripts = grep {
    local (@ARGV, $/) = (catfile('bin', $_));
    my $content = <>;
    $content =~ m/^=(?:head[1-6]|cut)/m ? 1 : ();
} @scripts;

my %extra_deps;
for ($^O) {
    /MSWin32/ && do {
        %extra_deps = (
            'Win32' => 0,
            'Win32::API' => 0,
            'Win32::TieRegistry' => 0,
        );
        last;
    };
    /haiku/ && do {
        %extra_deps = (
            'Haiku::SysInfo' => 0,
        );
        last;
    };
}

# We won't enforce JSON::PP if Cpanel::JSON::XS or JSON::XS is installed.
# But JSON serialisation is needed.
eval {require Cpanel::JSON::XS };
if ( $@ ) {
    eval { require JSON::XS };
    if ( $@ ) {
        $extra_deps{'JSON::PP'} = 0;
    }
    else {
        $extra_deps{'JSON::XS'} = 0;
    }
}
else {
    $extra_deps{'Cpanel::JSON::XS'} = 0;
}
my %posters;
my @ua_clients = qw/HTTP::Tiny LWP::UserAgent/;
for my $poster (@ua_clients) {
    eval "require $poster;";
    if ($@) { $posters{$poster} = 0 }
}
if (keys %posters == 3) {
    # Check for the curlbin as fallback
    local @INC = (@INC, 'lib');
    require Test::Smoke::Util;
    my $curlbin = Test::Smoke::Util::whereis('curl');
    if (!$curlbin) {
        $extra_deps{'HTTP::Tiny'} = 0;
    }
    else {
        print "Found $curlbin\n";
    }
}
else { # we have a perl module, so we need extra stuff
    exists $posters{$_} or $extra_deps{$_} = 0, last
        for @ua_clients;
    $extra_deps{'Net::SSLeay'} = 0;
    $extra_deps{'IO::Socket::SSL'} = 0;
    $extra_deps{'LWP::Protocol::https'} = 6 if exists($posters{'LWP::UserAgent'});
}

my %BUILD_REQUIRES = (
    'ExtUtils::MakeMaker' => '6.55_03',
);
my %TEST_REQUIRES = (
    'Test::More'       => 0.88,
    'Test::NoWarnings' => 0,
    'Test::Fatal'      => 0,
    'HTTP::Daemon'     => 0,
    'HTTP::Message'    => 0,
    'JSON'             => 4.10,
    'Path::Tiny'       => 0, # To be revised (?). Only used by tsarchivelog.pl
    ($mmver > 6.64 ? (%BUILD_REQUIRES) : ()),
);

my $test_requires = (
    $mmver >= 6.64
        ? 'TEST_REQUIRES'
        : "BUILD_REQUIRES"
);

my %wm = (
    NAME         => "Test::Smoke",
    DISTNAME     => "Test-Smoke",
    VERSION_FROM => "lib/Test/Smoke.pm",
    AUTHOR       => 'H.Merijn Brand <h.m.brand@xs4all.nl>, '
                  . 'Nicholas Clark <nick@plum.flirble.org> and '
                  . 'Abe Timmerman <abeltje@cpan.org>',
    ABSTRACT_FROM    => 'lib/Test/Smoke.pm',
    MIN_PERL_VERSION => '5.010',
    LICENSE          => "perl_5",

    dist => {
        COMPRESS => "gzip -9f",
        SUFFIX   => ".gz",
    },
    PREREQ_PM => {
        'URI'           => '1.53',
        'Capture::Tiny' => 0,
        'File::Spec'    => 0.82,
        'POSIX'         => 0,
        'System::Info'  => 0.050,
        'autodie'       => 0,
        'Getopt::Long'  => '2.39',
        ($test_requires eq 'PREREQ_PM' ? %TEST_REQUIRES : ()),
        %extra_deps,
    },
    PMLIBDIRS => [qw/ lib /],
    EXE_FILES => [ map "bin/$_", @scripts ],
    MAN1PODS  => {
        'lib/configsmoke.pod' => 'blib/man1/configsmoke.1',
        map { ("bin/$_" => "blib/man1/$_.1") } @pod_scripts,
    },
    test      => {
        TESTS => 't/*.t t/app/*.t',
    },
    META_ADD => {
        "meta-spec" => {
            version => 2,
        },
        "resources" => {
            homepage   => "http://perl5.test-smoke.org/",
            repository => {
                type => "git",
                url  => "https://github.com/Perl-Toolchain-Gang/Test-Smoke.git",
                web  => "https://github.com/Perl-Toolchain-Gang/Test-Smoke"
            },
            bugtracker => {
                web  => "https://github.com/Perl-Toolchain-Gang/Test-Smoke/issues"
            },
            x_IRC => "irc://irc.perl.org/#smoke",
        },
    },
);

if ($test_requires ne 'PREREQ_PM') {
    $wm{$test_requires} = \%TEST_REQUIRES;
}

WriteMakefile(
    %wm,
    %install
);

sub dir_prompt {

    GETDIR: {
        my $dir = &prompt; # & -> pass @_

        # thanks to perlfaq5
        $dir =~ s{^ ~ ([^/]*)}
                 {$1 ? ( getpwnam $1 )[7] : 
                       ( $ENV{HOME} || $ENV{LOGDIR} ||
                         "$ENV{HOMEDRIVE}$ENV{HOMEPATH}" )
                 }ex;

        my $cwd = cwd();
        my $dir_existed = -d $dir;
        File::Path::mkpath( $dir, 1, 0755 ) unless $dir_existed;
        chdir $dir or warn "Cannot chdir($dir): $!\n" and redo GETDIR;
        $dir = canonpath( cwd() );
        chdir $cwd or warn "Cannot chdir($cwd) back: $!\n";
        File::Path::rmtree( $dir ) unless $dir_existed;

        print "Got [$dir]\n";
        return $dir;
    }
}

package MY;

sub test {
    my $self = shift;
    my $orig = $self->SUPER::test(@_);

    $orig .= <<"EOM";

XTEST_FILES = xt/*.t
xtest ::
EOM

    my $varpfx = $^O eq 'MSWin32' ? '$$' : '\$$';
    $orig .= "\t"
           . qq{\$(FULLPERLRUN) "-e" "my ${varpfx}sw=q[-wl]; }
           . qq{${varpfx}sw .= q[v] if \$(TEST_VERBOSE); }
           . qq{system qq[prove ${varpfx}sw \$(XTEST_FILES)]"};

    return $orig;
}
1;
