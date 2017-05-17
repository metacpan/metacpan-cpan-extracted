#! /usr/bin/perl -w
use strict;
use 5.008003;
use ExtUtils::MakeMaker;
use Config;

my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0 }
use File::Spec::Functions qw( :DEFAULT rel2abs );
use Cwd;
use File::Path;

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

my $iscript = 'INSTALLSITESCRIPT';
unless ( eval "$mmver" >= eval "6.30_01" ) {
print "You are running MakeMaker v$mmver: fix INSTALLSCRIPT\n";
$iscript = 'INSTALLSCRIPT';
}

my %install = ( );
unless ( @ARGV ) {
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
    PREFIX   => $install_dir,
    $iscript => $install_dir,
    LIB      => $install_dir
);
}
my @scripts = qw(
    synctree.pl patchtree.pl mailrpt.pl W32Configure.pl
    configsmoke.pl smokeperl.pl runsmoke.pl sendrpt.pl
    archiverpt.pl smokestatus.pl chkbcfg.pl sysinfo.pl
    tssynctree.pl tsrunsmoke.pl tssendrpt.pl tsarchive.pl
    tssmokeperl.pl tsreport.pl
);

my %extra_deps;
for ($^O) {
    /MSWin32/ && do {
        %extra_deps = (
            'Win32' => 0,
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

# We won't enforce JSON::PP if JSON::XS is installed.
# But JSON serialisation is needed.
eval { require JSON::XS };
if ( $@ ) {
    $extra_deps{'JSON::PP'} = 0;
}
else {
    $extra_deps{'JSON::XS'} = 0;
}
my %posters;
for my $poster (qw/HTTP::Tiny LWP::UserAgent HTTP::Lite/) {
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
else {
    exists $posters{$_} or $extra_deps{$_} = 0, last
        for qw/HTTP::Tiny LWP::UserAgent HTTP::Lite/;
}

my %TEST_REQUIRES = (
    'Test::More'       => 0.88,
    'Test::NoWarnings' => 0,
    'HTTP::Daemon'     => 0,
    'HTTP::Message'    => 0,
);

my $test_requires = (
    $mmver >= 5.5503
        ? $mmver >= 6.64
            ? 'TEST_REQUIRES'
            : "BUILD_REQUIRES"
        : 'PREREQ_PM'
);

my %wm = (
    NAME          => "Test::Smoke",
    DISTNAME      => "Test-Smoke",
    VERSION_FROM  => "lib/Test/Smoke.pm",
    AUTHOR        => 'H.Merijn Brand <h.m.brand@xs4all.nl>, '.
                     'Nicholas Clark <nick@plum.flirble.org> and ' .
                     'Abe Timmerman <abeltje@cpan.org>',
    ABSTRACT_FROM => 'lib/Test/Smoke.pm',

    dist => {
        COMPRESS => "gzip -9f",
        SUFFIX   => ".gz",
    },
    PREREQ_PM     => {
        'CGI::Util'    => 0,
        'File::Spec'   => 0.82,
        'POSIX'        => 0,
        'System::Info' => 0.050,
        ($test_requires eq 'PREREQ_PM' ? %TEST_REQUIRES : ()),
        %extra_deps,
    },
    PMLIBDIRS     => [qw/ lib inc /],
    EXE_FILES     => \@scripts,
    test          => {
        TESTS => 't/*.t t/app/*.t',
    }
);

if ($test_requires ne 'PREREQ_PM') {
    $wm{$test_requires} = \%TEST_REQUIRES;
}

$mmver > 6.31 and $wm{LICENSE}  = "perl_5";
$mmver > 6.46 and $wm{META_ADD} = {
    "meta-spec" => {
        version    => 2,
    },
    "resources" => {
        homepage   => "http://perl5.test-smoke.org/",
        repository => {
            type   => "git",
            url    => "git://github.com/abeltje/Test-Smoke.git",
            web    => "https://github.com/abeltje/Test-Smoke",
        },
        x_IRC      => "irc://irc.perl.org/#smoke",
    },
};

WriteMakefile(
    %wm,
    %install
);

#sub MY::libscan {
#    my( $self, $path ) = @_;
#    my @nopaths = qw( .svn t private investigate );
#    my $patt = join '|', map {
#        /^\w/ and $_ = "\\b$_";
#        /\w$/ and $_ = "$_\\b";
#        $_;
#    } @nopaths;
#
#    return $path =~ m:$patt: ? "" : $path;
#}

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
