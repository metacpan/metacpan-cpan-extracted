#!perl

use strict;
use warnings;

use lib 'inc';
use Config;
use Config::AutoConf::SG;
use ExtUtils::Constant;
use ExtUtils::MakeMaker;
use File::Basename;
use File::Spec;
use Text::ParseWords;

my %RUN_DEPS = (
    'Carp'           => 0,
    'File::Basename' => 0,
    'File::Path'     => '2.00',
    'File::Spec'     => 0,
);
my %CONFIGURE_DEPS = (
    'ExtUtils::MakeMaker' => 0,
    'ExtUtils::Constant'  => '0.21',
    'Capture::Tiny'       => '0.06',
    'ExtUtils::CBuilder'  => '0.27',
    'Config::AutoConf'    => '0.317',
    'File::Basename'      => 0,
    'File::Spec'          => 0,
    'Text::ParseWords'    => 0,
    'parent'              => 0,
);
my %BUILD_DEPS = ();

my %TEST_DEPS = (
    'Test::More' => 0.90,
);

my $autoconf = Config::AutoConf::SG->new();
$autoconf->check_libstatgrab() or die <<EOD;
*******************************************
Couldn't find libstatgrab (at least 0.90)
which is required for this module.

To obtain it, go to
    http://www.i-scream.org/libstatgrab/
*******************************************
EOD

$autoconf->check_device_canonical();
$autoconf->check_sizeof_IVUV_fit_stat();

my $xsfile = "Statgrab.xs";
my $config_h = File::Spec->catfile(dirname($xsfile), 'config.h');
$autoconf->write_config_h($config_h);
_write_constants();

WriteMakefile1(
    MIN_PERL_VERSION => '5.008003',
    META_ADD         => {
        license     => ['perl_5', 'lgpl_2_1'],
        'meta-spec' => {version => 2},
        resources   => {
            homepage   => 'https://metacpan.org/release/Unix-Statgrab',
            repository => {
                url  => 'https://github.com/i-scream/Unix-Statgrab.git',
                web  => 'https://github.com/i-scream/Unix-Statgrab',
                type => 'git',
            },
            bugtracker => {
                web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Unix-Statgrab',
                mailto => 'bug-Unix-Statgrab@rt.cpan.org',
            },
            x_IRC         => "irc://irc.freenode.net/#libstatgrab",
            x_MailingList => "mailto:users\@i-scream.org'",
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::CPAN::Changes'                 => 0,
                    'Test::CheckManifest'                 => 0,
                    'Module::CPANTS::Analyse'             => '0.96',
                    'Test::Kwalitee'                      => 0,
                    'Test::Pod'                           => 0,
                    'Test::Pod::Coverage'                 => 0,
                    'Test::Pod::Spelling::CommonMistakes' => 0,
                    'Test::Spelling'                      => 0,
                },
            },
            configure => {
                requires => {%CONFIGURE_DEPS},
            },
            build => {requires => {%BUILD_DEPS}},
            test  => {
                recommends => {'Test::LeakTrace' => 0},
                requires   => {%TEST_DEPS}
            },
            runtime => {
                requires => {%RUN_DEPS},
            },
        },
    },
    NAME               => 'Unix::Statgrab',
    VERSION_FROM       => 'lib/Unix/Statgrab.pm',
    ABSTRACT_FROM      => 'lib/Unix/Statgrab.pm',
    LICENSE            => 'lgpl_2_1',
    AUTHOR             => ['Tassilo von Parseval <tassilo.von.parseval@rwth-aachen.de>', 'Jens Rehsack <sno@NetBSD.org>'],
    XS                 => {$xsfile => "Statgrab.c"},
    OBJECT             => q/$(O_FILES)/,
    INC                => $autoconf->_get_extra_compiler_flags,
    LIBS               => $autoconf->_get_extra_linker_flags,
    CONFIGURE_REQUIRES => \%CONFIGURE_DEPS,
    PREREQ_PM          => \%RUN_DEPS,
    BUILD_REQUIRES     => \%BUILD_DEPS,
    TEST_REQUIRES      => \%TEST_DEPS,
    clean              => {FILES => "Unix-Statgrab-* *.o config.h const-*.inc config.log"},
    test               => {TESTS => 't/*.t xt/*.t'},
);

sub WriteMakefile1
{    # originally written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if (exists($params{EXTRA_META}));
    die "License not specified"    if (!exists($params{LICENSE}));
    $params{TEST_REQUIRES}
      and $eumm_version < 6.6303
      and $params{BUILD_REQUIRES} = {%{$params{BUILD_REQUIRES} || {}}, %{delete $params{TEST_REQUIRES}}};
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{BUILD_REQUIRES}
      and $eumm_version < 6.5503
      and $params{PREREQ_PM} = {%{$params{PREREQ_PM} || {}}, %{delete $params{BUILD_REQUIRES}}};
    ref $params{AUTHOR}
      and "ARRAY" eq ref $params{AUTHOR}
      and $eumm_version < 6.5702
      and $params{AUTHOR} = join(", ", @{$params{AUTHOR}});
    delete $params{CONFIGURE_REQUIRES}    if ($eumm_version < 6.52);
    delete $params{MIN_PERL_VERSION}      if ($eumm_version < 6.48);
    delete $params{META_MERGE}            if ($eumm_version < 6.46);
    delete $params{META_ADD}{prereqs}     if ($eumm_version < 6.58);
    delete $params{META_ADD}{'meta-spec'} if ($eumm_version < 6.58);
    delete $params{META_ADD}              if ($eumm_version < 6.46);
    delete $params{LICENSE}               if ($eumm_version < 6.31);
    delete $params{AUTHOR}                if ($] < 5.005);
    delete $params{ABSTRACT_FROM}         if ($] < 5.005);
    delete $params{BINARY_LOCATION}       if ($] < 5.005);

    # more or less taken from Moose' Makefile.PL
    if ($params{CONFLICTS})
    {
        my $ok = CheckConflicts(%params);
        exit(0) if ($params{PREREQ_FATAL} and not $ok);
        my $cpan_smoker = grep { $_ =~ m/(?:CR_SMOKER|CPAN_REPORTER|AUTOMATED_TESTING)/ } keys %ENV;
        unless ($cpan_smoker || $ENV{PERL_MM_USE_DEFAULT})
        {
            sleep 4 unless ($ok);
        }
        delete $params{CONFLICTS};
    }

    WriteMakefile(%params);
}

sub _write_constants
{
    my @names = (
        qw(SG_ERROR_NONE SG_ERROR_INVALID_ARGUMENT SG_ERROR_ASPRINTF
          SG_ERROR_SPRINTF SG_ERROR_DEVICES SG_ERROR_DEVSTAT_GETDEVS
          SG_ERROR_DEVSTAT_SELECTDEVS SG_ERROR_DISKINFO SG_ERROR_ENOENT
          SG_ERROR_GETIFADDRS SG_ERROR_GETMNTINFO SG_ERROR_GETPAGESIZE
          SG_ERROR_HOST SG_ERROR_KSTAT_DATA_LOOKUP SG_ERROR_KSTAT_LOOKUP
          SG_ERROR_KSTAT_OPEN SG_ERROR_KSTAT_READ SG_ERROR_KVM_GETSWAPINFO
          SG_ERROR_KVM_OPENFILES SG_ERROR_MALLOC SG_ERROR_MEMSTATUS
          SG_ERROR_OPEN SG_ERROR_OPENDIR SG_ERROR_READDIR SG_ERROR_PARSE
          SG_ERROR_PDHADD SG_ERROR_PDHCOLLECT SG_ERROR_PDHOPEN SG_ERROR_PDHREAD
          SG_ERROR_PERMISSION SG_ERROR_PSTAT SG_ERROR_SETEGID SG_ERROR_SETEUID
          SG_ERROR_SETMNTENT SG_ERROR_SOCKET SG_ERROR_SWAPCTL SG_ERROR_SYSCONF
          SG_ERROR_SYSCTL SG_ERROR_SYSCTLBYNAME SG_ERROR_SYSCTLNAMETOMIB
          SG_ERROR_SYSINFO SG_ERROR_MACHCALL SG_ERROR_IOKIT SG_ERROR_UNAME
          SG_ERROR_UNSUPPORTED SG_ERROR_XSW_VER_MISMATCH SG_ERROR_GETMSG
          SG_ERROR_PUTMSG SG_ERROR_INITIALISATION SG_ERROR_MUTEX_LOCK
          SG_ERROR_MUTEX_UNLOCK),
        qw(sg_unknown_configuration sg_physical_host sg_virtual_machine
          sg_paravirtual_machine sg_hardware_virtualized),
        qw(sg_fs_unknown sg_fs_regular sg_fs_special sg_fs_loopback
          sg_fs_remote sg_fs_local sg_fs_alltypes),
        qw(SG_IFACE_DUPLEX_FULL SG_IFACE_DUPLEX_HALF SG_IFACE_DUPLEX_UNKNOWN),
        qw(SG_IFACE_DOWN SG_IFACE_UP),
        qw(SG_PROCESS_STATE_RUNNING SG_PROCESS_STATE_SLEEPING
          SG_PROCESS_STATE_STOPPED SG_PROCESS_STATE_ZOMBIE
          SG_PROCESS_STATE_UNKNOWN),
    );

    my $c_const  = File::Spec->catfile(dirname($xsfile), 'const-c.inc');
    my $xs_const = File::Spec->catfile(dirname($xsfile), 'const-xs.inc');

    # workaround #ifdef around each constant (stupid that it's not documented)
    open(my $c_fh, ">", $c_const) or die("Cannot open $c_const for writing: $!");
    foreach my $name (@names)
    {
        print $c_fh "#define $name $name\n";
    }
    ExtUtils::Constant::WriteConstants(
        NAME         => 'Unix::Statgrab',
        NAMES        => \@names,
        DEFAULT_TYPE => 'UV',
        C_FH         => $c_fh,
        XS_FILE      => $xs_const,
    );
    close($c_fh);

    return;
}

=head1 INSTALL

In case the automatic detection fails, one can use some different attemps
to succeed configuration:

=over 4

=item C<$ENV{PKG_CONFIG_PATH}>

Prepend or append the path where your C<libstatgrab.pc> resides

=item C<$ENV{libstatgrab_CFLAGS}>

Set this to the CFLAGS suitable to compile against C<statgrab.h>

=item C<$ENV{libstatgrab_LIBS}>

Set this to the LINKFLAGS suitable to link against C<libstatgrab.so>

=back

=cut
