#!/usr/bin/perl -w
use strict;
use 5.008003;
use Carp;

use Config;
use Cwd;
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Path;
use File::Spec::Functions;
use FindBin;
use lib $FindBin::Bin;
use lib catdir( $FindBin::Bin, 'lib' );
use lib catdir( $FindBin::Bin, updir(), 'lib' );
use lib catdir( $FindBin::Bin, updir(), 'lib', 'inc' );

use fallback catdir($FindBin::Bin, updir(), 'lib', 'inc'), catdir($FindBin::Bin, updir(), 'lib', 'inc');

use System::Info;
use Test::Smoke::Util qw(do_pod2usage whereis);
use Test::Smoke::Util::FindHelpers ':all';

use vars qw($conf);
our $VERSION = '0.091';

use Getopt::Long;
my %options = (
        config  => undef,
        jcl     => undef,
        log     => undef,
        default => undef,
        prefix  => undef,
        oldcfg  => 0,
        usedft  => undef,
        );
my $myusage = "Usage: $0 -p <prefix>[ -d <defaultsprefix>]";
GetOptions( \%options,
        'config|c=s', 'jcl|j=s', 'log|l=s',
        'prefix|p=s', 'default|d:s', 'usedft|des',

        'help|h', 'man',
        ) or do_pod2usage( verbose => 1, myusage => $myusage );

$options{ man} and
do_pod2usage( verbose => 2, exitval => 0, myusage => $myusage );
$options{help} and
do_pod2usage( verbose => 1, exitval => 0, myusage => $myusage );

$options{prefix} = 'smokecurrent' unless defined $options{prefix};

my %suffix = ( config => '_config', jcl => '', log => '.log' );
foreach my $opt (qw( config jcl log )) {
    my $key = defined $options{$opt} ? $opt : 'prefix';
    $options{$opt} = "$options{ $key }$suffix{ $opt }";
}

{
    local $@;
    eval { require $options{config} };
    my $load_error = $@;
    unless ( $load_error ) {
        $options{oldcfg} = 1;
        print "Using '$options{config}' for defaults.\n";
        $conf->{perl_version} eq '5.9.x'  and $conf->{perl_version} = 'blead';
        $conf->{perl_version} eq '5.11.x' and $conf->{perl_version} = 'blead';
        $conf->{perl_version} eq '5.13.x' and $conf->{perl_version} = 'blead';
        $conf->{perl_version} eq '5.15.x' and $conf->{perl_version} = 'blead';
    }

    if ( $load_error || $options{default} ) {
        my $df_key = $options{default} ? 'default' : 'prefix';
        my $df_config = "$options{ $df_key }_dfconfig";
        my $df_config_inc = $df_config;
        for my $dir ( @INC ) {
            my $ts_dir = File::Spec->catdir( $dir, 'Test', 'Smoke' );
            $df_config_inc = File::Spec->catfile( $ts_dir, $df_config );
    #        print "Checking for defaults [$df_config_inc]\n";
            -f $df_config_inc and last;
        }
        eval { require $df_config_inc };
        unless ( $@ ) {
            $options{oldcfg} = 0;
            print "Using '$df_config_inc' for more defaults.\n";
        }
    }
}

# -des will only work fully when $options{oldcfg}
unless ( $options{oldcfg} ) {
    defined $options{usedft}
        and print "Option '-des' not fully functional!\n";
} else {
    # -d like in ./Configure, works for oldcfg only!
    $options{usedft} ||= defined $options{default} &&
                         $options{default} eq "";
}

=head1 NAME

configsmoke.pl - Create a configuration for B<tssmokeperl.pl>

=head1 SYNOPSIS

    $ perl configsmoke.pl -p <prefix>[ -d <defaultsprefix>]

or regenerate from previous _config:

    $ perl configsmoke.pl -p <prefix> -des

=head1 OPTIONS

Current options:

  -d dfvalsprefix   Set prefix for a _dfconfig file (<prefix>)
  -c configprefix   When omitted 'perlcurrent' is used
  -j jclprefix      When omitted 'perlcurrent' is used
  -l logprefix      When omitted 'perlcurrent' is used
  -p prefix         Set -c and -j and -l at once

  -des              confirm all answers (needs previous _config)

=cut

sub is_win32() { $^O eq 'MSWin32' }
sub is_vms()   { $^O eq 'VMS'     }

my %config = ( perl_version => $conf->{perl_version} || 'blead' );

my %mailers = get_avail_mailers();
my @mailers = sort keys %mailers;
my @syncers = get_avail_sync();
my $syncmsg = join "\n", @{ {
    git      => "\tgit - Use a git-repository [preferred]",
    rsync    => "\trsync - Use the rsync(1) program",
    copy     => "\tcopy - Use File::Copy to copy from a local directory",
    hardlink => "\thardlink - Copy from a local directory using link()",
#    snapshot => "\tsnapshot - Get a snapshot using Net::FTP (or LWP::Simple)",
} }{ @syncers };
my @untars = get_avail_tar();
my $untarmsg = join "", map "\n\t$_" => @untars;

my %vdirs = map {
    my $vdir = $_;
    is_vms and $vdir =~ tr/.//d;
    ( $_ => $vdir )
} qw( 5.18.x 5.20.x 5.22.x 5.24.x 5.26.x );

my %versions = (
    '5.18.x' => {
        gbranch => 'maint-5.18',
        source  => 'perl5.git.perl.org::perl-5.18.x',
        server  => 'http://perl5.git.perl.org',
        sdir    => '/perl.git/snapshot/refs/heads/',
        sfile   => 'maint-5.18.tar.gz',
        pdir    => '/pub/apc/perl-current-diffs',
        ddir    => File::Spec->catdir(
            cwd(),
            File::Spec->updir,
            'perl-current'
        ),

        text    => 'Perl 5.18 maint',
        cfg     => (
            is_win32
                ? 'w32current.cfg'
                : is_vms ? 'vmsperl.cfg' : 'perlmaint.cfg'
        ),
        is56x   => 0,
    },
    '5.20.x' => {
        gbranch => 'maint-5.20',
        source  => 'perl5.git.perl.org::perl-5.20.x',
        server  => 'http://perl5.git.perl.org',
        sdir    => '/perl.git/snapshot/refs/heads/',
        sfile   => 'maint-5.20.tar.gz',
        pdir    => '/pub/apc/perl-current-diffs',
        ddir    => File::Spec->catdir(
            cwd(),
            File::Spec->updir,
            'perl-current'
        ),

        text    => 'Perl 5.20 maint',
        cfg     => (
            is_win32
                ? 'w32current.cfg'
                : is_vms ? 'vmsperl.cfg' : 'perlmaint.cfg'
        ),
        is56x   => 0,
    },
    '5.22.x' => {
        gbranch => 'maint-5.22',
        source  => 'perl5.git.perl.org::perl-5.22.x',
        server  => 'http://perl5.git.perl.org',
        sdir    => '/perl.git/snapshot/refs/heads/',
        sfile   => 'maint-5.22.tar.gz',
        pdir    => '/pub/apc/perl-current-diffs',
        ddir    => File::Spec->catdir(
            cwd(),
            File::Spec->updir,
            'perl-current'
        ),

        text    => 'Perl 5.22 maint',
        cfg     => (
            is_win32
                ? 'w32current.cfg'
                : is_vms ? 'vmsperl.cfg' : 'perlmaint.cfg'
        ),
        is56x   => 0,
    },
    '5.24.x' => {
        gbranch => 'maint-5.24',
        source  => 'perl5.git.perl.org::perl-5.24.x',
        server  => 'http://perl5.git.perl.org',
        sdir    => '/perl.git/snapshot/refs/heads/',
        sfile   => 'maint-5.24.tar.gz',
        pdir    => '/pub/apc/perl-current-diffs',
        ddir    => File::Spec->catdir(
            cwd(),
            File::Spec->updir,
            'perl-current'
        ),

        text    => 'Perl 5.24 maint',
        cfg     => (
            is_win32
                ? 'w32current.cfg'
                : is_vms ? 'vmsperl.cfg' : 'perlmaint.cfg'
        ),
        is56x   => 0,
    },
    '5.26.x' => {
        gbranch => 'maint-5.26',
        source  => 'perl5.git.perl.org::perl-5.26.x',
        server  => 'http://perl5.git.perl.org',
        sdir    => '/perl.git/snapshot/refs/heads/',
        sfile   => 'maint-5.26.tar.gz',
        pdir    => '/pub/apc/perl-current-diffs',
        ddir    => File::Spec->catdir(
            cwd(),
            File::Spec->updir,
            'perl-current'
        ),

        text    => 'Perl 5.26 maint',
        cfg     => (
            is_win32
                ? 'w32current.cfg'
                : is_vms ? 'vmsperl.cfg' : 'perlmaint.cfg'
        ),
        is56x   => 0,
    },
    'blead' => {
        gbranch => 'blead',
        source  => 'perl5.git.perl.org::perl-current',
        server  => 'http://perl5.git.perl.org',
        sdir    => '/perl.git/snapshot/',
        sfile   => '',
        pdir    => '/pub/apc/perl-current-diffs',
        ddir    => File::Spec->catdir(
            cwd(),
            File::Spec->updir,
            'perl-current'
        ),

        text    => 'Perl 5.28 to-be',
        cfg     => (
            is_win32
                ? 'w32current.cfg'
                : is_vms ? 'vmsperl.cfg' : 'perlcurrent.cfg'
        ),
        is56x   => 0,
    },
);
my @pversions = sort {
    _perl_numeric_version( $a ) <=> _perl_numeric_version( $b )
} grep /^5\./, keys %versions;
push @pversions, 'blead';
my $smoke_version = join "\n", map {
    "\t$_ - $versions{ $_ }->{text}"
} @pversions;

my %opt = (
    perl_version => {
        msg => "Which version are you going to smoke?\n$smoke_version",
        alt => [ @pversions ],
        dft => $pversions[-1],
    },

    # is this a perl-5.6.x smoke?
    is56x => {
        msg => "Is this configuration for perl-5.6.2 (MAINT)?
\tThis will ensure only one pass of 'make test'.",
        alt => [qw( N y )],
        dft => 'N',
    },
    # Destination directory
    ddir => {
        msg => "Where would you like the new source-tree?
\tThis directory is also used as the build directory.",
        alt => [ ],
        dft => File::Spec->catdir( File::Spec->rel2abs( File::Spec->updir ),
                                   'perl-current' ),
        chk => '.+',
    },
    use_old => {
        msg => "It looks like there is already a source-tree there.\n" .
               "Should it still be used for smoke testing?",
        alt => [qw( N y )],
        dft => 'n',
    },
    # misc
    cfg => {
        msg => 'Which build-configuration file would you like to use?',
        alt => [ ],
        dft => File::Spec->rel2abs(
                ( is_win32 ? 'w32current.cfg'
                : is_vms ? 'vmsperl.cfg' : 'perlcurrent.cfg' ) ),
    },
    change_cfg => {
        msg => undef, # Set later...
        alt => [qw( Y n )],
        dft => 'y',
    },
    umask => {
        msg => 'What umask can be used (0 preferred)?',
        alt => [ ],
        dft => '0',
    },
    renice => {
        msg => "With which value should 'renice' be run " .
               "(leave '0' for no 'renice')?",
        alt => [ 0..20 ],
        dft => 0,
    },
    v => {
        msg => 'How verbose do you want the output?',
        alt => [qw( 0 1 2 )],
        dft => 1,
    },
    # syncing the source-tree
    want_forest => {
        msg => "Would you like the 'Nick Clark' master sync trees (forest)?
\tPlease see 'perldoc $0' for an explanation.",
        alt => [qw( N y )],
        dft => 'n',
    },
    forest_mdir => {
        msg => 'Where would you like the master source-tree?',
        alt => [ ],
        dft => File::Spec->rel2abs( File::Spec->catdir( File::Spec->updir,
                                                        'perl-master' ) ),
        chk => '.+',
    },
    forest_hdir => {
        msg => 'Where would you like the intermediate source-tree?',
        alt => [ ],
        dft => File::Spec->catdir( File::Spec->rel2abs( File::Spec->updir ),
                                   'perl-inter' ),
        chk => '.+',
    },
    fsync => {
        msg => "How would you like to sync your master source-tree?\n$syncmsg",
        alt => [ @syncers ],
        dft => $syncers[0],
    },
    sync_type => {
        msg => "How would you like to sync your source-tree?\n$syncmsg",
        alt => [ @syncers ],
        dft => $syncers[0],
    },
    source => {
        msg => 'Where would you like to rsync from?',
        alt => [ ],
        dft => 'perl5.git.perl.org::perl-current',
    },
    rsync => {
        msg => 'Which rsync program should be used?',
        alt => [ ],
        dft => ( whereis( 'rsync' ) || '' ),
    },
    opts => {
        msg => 'Which arguments should be used for rsync?',
        alt => [ ],
        dft => '-az --delete',
    },

    server => {
        msg => "Where would you like to FTP the snapshots from?
\tsnapshots on a webserver can be downloaded with the use
\tof LWP::Simple. Just have the server-name start with http://",
        alt => [ ],
        dft => 'ftp.funet.fi',
    },
    sdir => {
        msg => 'Which directory should the snapshots be FTPed from?',
        alt => [ ],
        dft => '/pub/languages/perl/snap',
    },
    sfile => {
        msg => "Which file should be downloaded?
\tLeave empty to automatically find newest.",
        alt => [ ],
        dft => '',
    },

    gitbin => {
        msg => "Which git binary do you want to use.",
        alt => [ ],
        dft => whereis('git'),
    },
    gitorigin => {
        msg => "Git main repository?",
        alt => [ ],
        dft => 'git://perl5.git.perl.org/perl5.git',
    },
    gitdir => {
        msg => "Directory for the local git repository?",
        alt => [ ],
        dft => File::Spec->catdir(
            File::Spec->rel2abs(File::Spec->updir),
            'git-perl'
        ),
    },
    gitdfbranch => {
        msg => "Which branch should be smoked by default?",
        alt => [ ],
        dft => 'blead',
    },
    gitbranchfile => {
        msg => "Filename to put branchname for smoking in?",
        alt => [ ],
        dft => undef,
    },

    tar => {
        msg => "How should the snapshots be extracted?
Examples:$untarmsg",
        alt => [ ],
        dft => ( (get_avail_tar())[0] || '' ),
    },

    snapext => {
        msg => 'What type of snapshots should be downloaded?',
        alt => [qw( tgz tbz )],
        dft => 'tgz',
    },

    unzip => {
        msg => 'How should the patches be unzipped?',
        alt => [ ],
        dft => ( whereis( 'gzip' ) . " -cd" ),
    },

    cleanup => {
        msg => "Remove applied patch-files?\n" .
               "0(none) 1(snapshot)",
        alt => [qw( 0 1 )],
        dft => 1,
    },

    cdir => {
        msg => 'From which directory should the source-tree be copied?',
        alt => [ ],
        dft => undef,
        chk => '.+',
    },

    hdir => {
        msg => 'From which directory should the source-tree be hardlinked?',
        alt => [ ],
        dft => undef,
        chk => '.+',
    },

    patchbin => {
        msg => undef,
        alt => [ ],
        dft => ( find_a_patch() || '' ),
    },

    popts => {
        msg => undef,
        alt => [ ],
        dft => '',
    },

    pfile => {
        msg => "What file is used for specifying patches " .
               "(leave empty for none)?
\tPlease read the documentation.",
        alt => [ ],
        dft => ''
    },

    # skip_tests
    skip_tests => {
        msg => "What file is used for specifying tests to skip " .
               "(leave empty for none)?
\tPlease read the documentation.",
        alt => [ ],
        dft => ''
    },

    # make fine-tuning
    makeopt => {
        msg => <<EOT,
Specify extra arguments for "$Config{make}".
\t(for the build step and test-prep step)
EOT
        alt => [ ],
        dft => '',
    },
    testmake => {
        msg => <<EOT,
Specify a different make program for "make _test".
EOT
        alt => [ ],
        dft => ( $Config{make} ? $Config{make} : 'make' ),
    },
    harnessonly => {
        msg => 'Use harness only (skip TEST)?',
        alt => [qw( y N )],
        dft => ( $^O =~ /VMS/i ? 'y' : 'n' ),
    },
    hasharness3 => {
        msg => "",
        alt => [ ],
        dft => 0,
    },
    harness3opts => {
        msg => <<EOT,
Extra options for Test::Harness 3 (HARNESS_OPTIONS)
\tUse 'j5' for parallel testing.
EOT
        alt => [ ],
        dft => '',
    },

    # Test::Smoke::Gateway database
    poster => {
        msg => "The type of HTTP POST system to use.",
        alt => [get_avail_posters()],
        dft => '',
    },
    smokedb_url => {
        msg => <<EOT,
Send smoke results to the SmokeDB? (url)
\t(Leave empty for no.)
EOT
        alt => [ ],
        dft => 'https://perl5.test-smoke.org/report',
    },
    send_log => {
        msg => 'Do you want to send the logfile with the report?',
        alt => [qw( always on_fail never )],
        dft => 'on_fail',
    },
    send_out => {
        msg => 'Do you want to send the outfile with the report?',
        alt => [qw( always on_fail never )],
        dft => 'never',
    },
    ua_timeout => {
        msg => '',
        alt => [ ],
        dft => undef,
    },

    hostname => {
        msg => 'Use the hostname option to override System::Info->hostname',
        alt => [ ],
        dft => undef,
    },
    # user_note
    user_note => {
        msg => "",
        alt => [ ],
        dft => undef,
    },
    un_file => {
        msg => <<EOT,
In which file will you store your personal notes?
\t(Leave empty for none.)
EOT
        alt => [ ],
        dft => undef,
    },
    un_position => {
        msg => "Where do you want your personal notes in the report?",
        alt => [qw/top bottom/],
        dft => 'bottom',
    },

    # mail stuff
    mail => {
        msg => "Would you like to email your reports?",
        alt => [qw( N y )],
        dft => 'n',
    },
    mail_type => {
        msg => 'Which send facility should be used?',
        alt => [ @mailers ],
        dft => $mailers[0],
        nocase => 1,
    },
    mserver => {
        msg => 'Which SMTP server should be used to send the report?' .
               "\nLeave empty to use local sendmail",
        alt => [ ],
        dft => 'localhost',
    },
    muser => {
        msg => 'Which username should be used for the SMTP server?',
        alt => [ ],
        dft => '',
    },
    mpass => {
        msg => 'Which password should be used for the SMTP server?' .
               "\nLeave empty to be prompted when sending email",
        alt => [ ],
        dft => '',
    },

    to => {
       msg => <<EOMSG,
To which address(es) should the report *always* be send?
\t(comma separated list, *please* do not include perl5-porters!)
EOMSG
       alt => [ ],
       dft => 'smokers-reports@perl.org',
       nck => '\bperl5-porters@perl.org\b',
    },

    bcc => {
       msg => <<EOMSG,
To which address(es) should the report *always* be BCCed?
\t(comma separated list, *please* do not include perl5-porters!)
EOMSG
       alt => [ ],
       dft => '',
       nck => '\bperl5-porters@perl.org\b',
    },

    swbcc => {
        msg => <<EOMSG,
Specify the switch your mailx uses for Blind Carbon Copy (Bcc:) addresses.
\tSome versions of mailx use '~b' and not '-b'.
EOMSG
        alt => [ ],
        dft => ( $^O =~ /hpux|dec_osf/ ? '~b' : '-b' ),
    },

    cc => {
       msg => <<EOMSG,
To which address(es) should the report be CCed *on fail*?
\t(comma separated list, *please* do not include perl5-porters!)
EOMSG
       alt => [ ],
       dft => '',
       nck => '\bperl5-porters@perl.org\b',
    },

    swcc => {
        msg => <<EOMSG,
Specify the switch your mailx uses for Carbon Copy (Cc:) addresses.
\tSome versions of mailx use '~c' and not '-c'.
EOMSG
        alt => [ ],
        dft => ( $^O =~ /hpux|dec_osf/ ? '~c' : '-c' ),
    },

    ccp5p_onfail => {
        msg => <<EOMSG,
Would you like your failed smoke reports CCed to perl5-porters?
EOMSG
        alt => [qw( y N )],
        dft => 'n',
    },

    from => {
        msg => 'Which address should be used for From?',
        alt => [ ],
        dft => '',
    },
    force_c_locale => {
        msg => "Should \$ENV{LC_ALL} be forced to 'C'?",
        alt => [qw( N y )],
        dft => 'n',
    },
    defaultenv => {
        msg => "Run the test-suite without \$ENV{PERLIO}?",
        alt => ( is_win32 ? [qw( n Y )] : [qw( N y )] ),
        dft => ( is_win32 ? 'y' : 'n' ),
    },
    locale => {
        msg => 'What locale should be used for extra testing ' .
               '(leave empty for none)?',
        alt => [ ],
        dft => '',
        chk => '(?:utf-?8$)|^$',
    },
    smartsmoke => {
        msg => 'Skip smoke unless patchlevel changed?',
        alt => [qw( Y n )],
        dft => 'y',
    },
    killtime => {
        msg => <<EOT,
Should this smoke be aborted on/after a specific time?
\tuse HH:MM to specify a point in time (24 hour notation)
\tuse +HH:MM to specify a duration
\tleave empty to finish the smoke without aborting
EOT
        dft => "",
        alt => [ ],
        chk => '^(?:(?:\+\d+)|(?:(?:[0-1]?[0-9])|(?:2[0-3])):[0-5]?[0-9])|$',
    },
    # Archive?
    adir => {
        msg => <<EOT,
Which directory should be used for the archives?
\tLeave empty for no archiving.
EOT
        alt => [ ],
        dft => "",
    },
    # Some ENV stuff
    perl5lib => {
        msg => "What value should be used for PERL5LIB in the jcl wrapper?
\t(Make empty, with single space, to not set it.)",
        alt => [ ],
        dft => (exists $ENV{PERL5LIB} ? $ENV{PERL5LIB} : ''),
    },
    perl5opt => {
        msg => "What value should be used for PERL5OPT in the jcl wrapper?
\t(Make empty, with single space, to not set it.)",
        alt => [ ],
        dft => (exists $ENV{PERL5OPT} ? $ENV{PERL5OPT} : ''),
    },
    # Schedule stuff
    docron => {
        msg => 'Should the smoke be scheduled?',
        alt => [qw( Y n )],
        dft => 'n',
    },
    crontime => {
        msg => 'At what time should the smoke be scheduled?',
        alt => [ ],
        dft => '22:25',
        chk => '(?:random|(?:[012]?\d:[0-5]?\d))',
    },
);

print <<EOMSG;

Welcome to the Perl core smoke test suite.

You will be asked some questions in order to configure this test suite.
Please make sure to read the documentation "perldoc configsmoke.pl"
in case you do not understand a question.

* Values in angled-brackets (<>) are alternatives (none other allowed)
* Values in square-brackets ([]) are default values (<Enter> confirms)
* Use single space to clear a value
* Answer '&-d' to continue with all default answers

EOMSG

my $arg;

=head1 DESCRIPTION

B<Test::Smoke> is the symbolic name for a set of scripts and modules
that try to run the perl core tests on as many configurations as possible
and combine the results into an easy to read report.

The main script is F<tssmokeperl.pl>, and this uses a configuration file
that is created by this program (F<configsmoke.pl>).  There is no default
configuration as some actions can be rather destructive, so you will need
to create your own configuration by running this program!

By default the configuration file created is called F<smokecurrent_config>,
this can be changed by specifying the C<< -c <prefix> >> or C<< -p <prefix> >>
switch at the command line (C<-c> will override C<-p> when both are specified).

    $ perl configsmoke.pl -c mysmoke

will create F<mysmoke_config> as the configuration file.

After you are done configuring, a small job command list is written.
For MSWin32 this is called F<smokecurrent.cmd> otherwise this is called
F<smokecurrent.sh>. Again the default prefix can be overridden by specifying
the C<< -j <prefix> >> or C<< -p <prefix> >> switch.

All output (stdout, stderr) from F<tssmokeperl.pl> and its sub-processes
is redirected to a logfile called F<smokecurrent.log> by the small jcl.
(Use C<< -l <prefix> >> or C<< -p <prefix> >> to override).

There are two additional configuration default files
F<smoke562_dfconfig> and F<smoke58x_dfconfig> to help you configure
B<Test::Smoke> for these two maintenance branches of the source-tree.

To create a configuration for the perl 5.8.x branch:

    $ perl configsmoke.pl -p smoke58x

This will read additional defaults from F<smoke58x_dfconfig> and create
F<smoke58x_config> and F<smoke58x.sh>/F<smoke58x.cmd> and logfile will be
F<smoke58x.log>.

To create another configuration for the same branch (and have the
right defaults) you can add the C<-d> option:

    $ perl configsmokepl -p snap58x -d smoke58x


To create a configuration for the perl 5.6.2 brach:

    $ perl configsmoke.pl -p smoke562

=head1 CONFIGURATION

Use of the program:

=over 4

=item *

Values in angled-brackets (<>) are alternatives (none other allowed)

=item *

Values in square-brackets ([]) are default values (<Enter> confirms)

=item *

Use single space to clear a value

=back

Here is a description of the configuration sections.

=over 4

=item perl_version

C<perl_version> sets a number of default_values.  This makes the
F<smoke5?x_dfconfig> files almost obsolete, although they still
provide a nice way to set the prefix and set the perl_version.

=cut

$arg = 'perl_version';
my $pversion = prompt( $arg );
$config{ $arg } = $pversion;

foreach my $var ( keys %{ $versions{ $pversion } } ) {
    $var eq 'text' and next;
    $opt{ $var }->{dft} = $versions{ $pversion }->{ $var };
}

$config{is56x} = $versions{ $pversion }->{is56x};

# Now we need to reset avail_sync; no snapshots for 5.6.x!
$opt{fsync}->{alt} = $opt{sync_type}->{alt} = [ get_avail_sync() ];
$opt{fsync}->{dft} = $opt{sync_type}->{dft} = $opt{fsync}->{alt}[0];

=item ddir

C<ddir> is the destination directory. This is used to put the
source-tree in and build perl. If a source-tree appears to be there
you will need to confirm your choice.

=cut

{
    # Hack -des (--usedft) to keep the safeguards
    local $options{usedft} = $options{usedft};
    BUILDDIR: {
        $arg = 'ddir';
        my $ddir = chk_dir( $conf->{$arg} || $config{$arg} )
                || $opt{$arg}->{dft};
        $conf->{$arg} = $config{$arg} = $ddir;
        $config{ $arg } = prompt_dir( $arg );
        $options{usedft} = $options{oldcfg};
        my $cwd = cwd;
        unless ( chdir $config{ $arg } ) {
            warn "Can't chdir($config{ $arg }): $!\n";
            redo BUILDDIR;
        }
        my $bdir = $config{ $arg } = cwd;
        if ( is_win32 && Win32::FsType() ne 'NTFS' ) {
            print "*** WHOA THERE!!! ***\n";
            print "\tYou are on MSWin32, ";
            print "but do not use a NTFS filesystem to build perl.\n"
        }

        chdir $cwd or die "Can't chdir($cwd) back: $!\n";
        if ( $cwd eq $bdir ) {
            print "The current directory *cannot* be used for smoke testing\n";
            redo BUILDDIR;
        }

        $config{ $arg } = File::Spec->canonpath( $config{ $arg } );
        my $manifest  = File::Spec->catfile( $config{ $arg }, 'MANIFEST' );
        my $dot_patch = File::Spec->catfile( $config{ $arg }, '.patch' );
        if ( -e $manifest && -e $dot_patch ) {
            $opt{use_old}->{dft} = $options{oldcfg} &&
                                   ($conf->{ddir}||"") eq $config{ddir}
                ? 'y' : $opt{use_old}->{dft};
            my $use_old = prompt_yn( 'use_old' );
            redo BUILDDIR unless $use_old;
        }
    }
}

=item cfg

C<cfg> is the path to the file that holds the build-configurations.
There are several build-cfg files provided with the distribution:

=over 4

=item F<perlcurrent.cfg> for 5.11.x+ on unixy systems

=item F<perl510x.cfg> for 5.10.x (MAINT) on unixy systems

=item F<perl58x.cfg> for 5.8.x (MAINT) on unixy systems

=begin nomoresupport

=item F<perl562.cfg> for 5.6.2 (MAINT) on unixy systems

=item F<perl55x.cfg> for 5.005_04 (MAINT) on unixy systems

=end nomoresupport

=item F<w32current.cfg> for 5.8.x+ on MSWin32

=item F<vmsperl.cfg> for 5.8.x+ on OpenVMS

=back

=begin unsupported

Note: 5.6.2 on MSWin32 is not yet provided, but commenting out the
B<-Duselargefiles> section from F<w32current.cfg> should be enough.

=end unsupported

=cut

$arg = 'cfg';
default_buildcfg( $config{cfg} || $opt{cfg}{dft}, $config{perl_version} );
$config{ $arg } = prompt_file( $arg );
check_buildcfg( $config{ $arg } );

=item Nick Clark hardlink forest

Here is how Nick described it to me:

My plan is to use a few more directories, and avoid make distclean:

=over 4

=item 1

rsync as before, but to a master directory. this directory is only used
for rsyncing from the server

=item 2

copy that directory (as a hardlink forest) - gnu cp can do it as cp -lr,
and I have a perl script to replicate that (which works nicely on FreeBSD)
as a clean master source directory for this smoke session

=item 3

run the regen headers script (which 5.9.0 now has as a distinct script)
rather than just a Makefile target

I now have a clean, up-to-date source tree with accurate headers. For each
smoking configuration

=item 4

copy that directory (hard links again)

=item 5

in the copy directory. Configure, build and test

=item 6

delete the copy directory

=back

deleting a directory seems to be faster than make distclean.

=cut

# Check to see if you want the Nick Clark forest
$arg = 'want_forest';
$opt{ $arg }{dft} = exists $conf->{sync_type}
                  ? $conf->{sync_type} eq 'forest'
                  : $opt{ $arg }{dft};
my $want_forest = prompt_yn( $arg );
FOREST: {
    last FOREST unless $want_forest;

    $config{mdir} = prompt_dir( 'forest_mdir', 'mdir' );

    $config{fdir} = prompt_dir( 'forest_hdir', 'fdir' );

    $config{sync_type} = 'forest';
}

=item sync_type (fsync)

C<sync_type> (or C<fsync> if you want_forest) can be one of four:

=over 4

=item rsync

This will use the B<rsync> program to sync up with the repository.
F<configsmoke.pl> checks to see if it can find B<rsync> in your path.

The default switches passed to B<rsync> are: S<< B<-az --delete> >>

=item snapshot

This will use B<Net::FTP> to try to find the latest snapshot on
<ftp://ftp.funet.fi/languages/perl/snap/>.

You can also get the perl-5.8.x snapshots (and others) via HTTP
if you have B<LWP> installed. There are two things you should remember:

=over 8

=item 1. start the server-name B<http://>

=item 2. the snapshot-file must be specified.

=back

Snapshots are not in sync with the repository, so if you have a working
B<patch> program, you can choose to "upgrade" your snapshot by fetching
all the seperate patches from the repository and applying them.

=item copy

This will use B<File::Copy> and B<File::Find> to just copy from a
local source directory.

=item hardlink

This will use B<File::Find> and the B<link> function to copy from a
local source directory. (This is also used if you choose "forest".)

=back

See also L<Test::Smoke::Syncer>

=cut

$arg = $want_forest ? 'fsync' : 'sync_type';
$config{ $arg } = lc prompt( $arg );

SYNCER: {
    local *_; $_ = $config{ $arg};
    /^rsync$/ && do {
        $arg = 'source';
        $config{ $arg } = prompt( $arg );

        $arg = 'rsync';
        $config{ $arg } = prompt( $arg );

        $arg = 'opts';
        $config{ $arg } = prompt( $arg );

        last SYNCER;
    };

    /^git$/ && do {
        $arg = 'gitbin';
        $config{$arg} = prompt($arg);

        $arg = 'gitorigin';
        $config{$arg} = prompt($arg);

        $arg = 'gitdir';
        $config{$arg} = prompt_dir($arg);

        $config{gitdfbranch} = $versions{$pversion}{gbranch};
        $arg = 'gitbranchfile';

        $opt{$arg}{dft} = "$options{prefix}.gitbranch";
        $config{$arg} = prompt_file($arg, 1);

        if (open my $gb, '>', $config{gitbranchfile}) {
            print {$gb} $config{gitdfbranch};
            close $gb;
            print "Wrote $config{gitbranchfile}...\n";
        }
        else {
            print "Error writing to $config{gitbranchfile}: $!\n";
        }

        last SYNCER;
    };


    /^snapshot$/ && do {
        for $arg ( qw( server sdir sfile ) ) {
            if ( $arg ne 'server' && $config{server} =~ m|^https?://|i ) {
                $opt{ $arg }->{msg} =~ s/\bFTPed/HTTPed/;
                $opt{ $arg }->{msg} =~ s/^\tLeave.+\n//m;
            }
            $config{ $arg } = prompt( $arg );
        }
        unless ( $config{sfile} ) {
            $arg = 'snapext';
            $config{ $arg } = prompt( $arg );
        }
        $arg = 'tar';
        $config{ $arg } = prompt( $arg );

        $arg = 'cleanup';
        $config{ $arg } = prompt( $arg );

        last SYNCER;
    };

    /^copy$/ && do {
        $arg = 'cdir';
        $config{ $arg } = prompt( $arg );
        while ( $config{ $arg } eq $config{ddir} ) {
            print "Source and destination directory cannot be the same!\n";
            $config{ $arg } = '';
            $config{ $arg } = prompt( $arg );
        }

        last SYNCER;
    };

    /^hardlink$/ && do {
        $arg = 'hdir';
        $config{ $arg } = prompt_dir( $arg );

        last SYNCER;
    };
}

=item pfile

C<pfile> is the path to a textfile that holds the names of patches to
be applied before smoking. This can be used to run a smoke test on proposed
patches that have not been applied (yet) or to see the effect of
reversing an already applied patch. The file format is simple:

=over 8

=item * one patchfile per line

=item * optionally followed by ';' and options to pass to patch

=item * optionally followed by ';' and a description for the patch

=back

If the file does not exist yet, a skeleton version will be created
for you.

You will need a working B<patch> program to use this feature.

B<TODO>:
There is an issue when using the "forest" sync, but I will look into that.

=cut

# Is it just my NetBSD-1.5 box with an old patch?
my $patchbin = find_a_patch();
PATCHER: {
    last PATCHER unless $patchbin;
    $config{patchbin} = $patchbin;
    print "\nFound [$config{patchbin}]";
    $arg = 'pfile';
    $opt{$arg}{dft} = "$options{prefix}.patchup";
    $config{ $arg } = prompt_file( $arg, 1 );

    if ( $config{ $arg } ) {
        $config{patch_type}  = 'multi';
        last PATCHER if -f $config{ $arg };
        local *PATCHES;
        open PATCHES, "> $config{$arg}" or last PATCHER;
        print PATCHES <<EOMSG;
# Put one filename of a patch on a line, optional args for patch
# follow the filename separated by a semi-colon (;) [-p1] is default
# optionally followed by another ';' and description (added to patchlevel.h)
# /path/to/patchfile.patch;-p0 -R;Description for this patch
# Empty lines and lines starting with '#' are ignored
# File paths are relative to '$config{ddir}'
# If your patch requires 'regen_perly' you'll need Bison 2 and
# uncomment the next line (keep the exclamation-point there):
#!perly
EOMSG
        close PATCHES or last PATCHER;
        print "Created skeleton '$config{$arg}'\n";
    }
}

=item skip_tests

This is a MANIFEST-like file with the paths to tests that should be
skipped for this smoke.

The process involves on the fly modification of F<MANIFEST> for tests
in F<lib/> and F<ext/> and renaming of core-tests in F<t/>.

=cut

SKIP_TESTS: {
    $arg = 'skip_tests';
    $opt{$arg}{dft} = "$options{prefix}.skiptests";
    $config{$arg} = prompt_file($arg, 1);
    if ($config{$arg} && !-f $config{$arg}) {
        if (open my $toskip, '>', $config{$arg}) {
            print $toskip "# One test name on a line\n";
            close $toskip;
            print "Created skeleton '$config{$arg}'...\n";
        }
        else {
            print "Error creating skeleton '$config{$arg}': $!\n";
        }
    }
}

=item hostname

In the case C<< System::Info->hostname >> needs to be overridden.

=cut

HOSTNAME: {
    $arg = 'hostname';
    my $hostname = System::Info::si_uname('n');
    $opt{$arg}{msg} .= "\n   Leave empty to use default '$hostname'";
    $config{$arg} = prompt($arg);
}

=item user_note

This gives you a way of adding personal information to the report.

B<un_file> is the filename where the text to insert into the report is set.

B<user_note> is the old way to add this text.

B<un_position> specify if you want the user_note on TOP or at the BOTTOM of te
report.

=cut

USER_NOTE: {
    $arg = 'un_file';
    $opt{$arg}{dft} = "$options{prefix}.usernote";
    $config{$arg} = prompt_file($arg, 1);

    last USER_NOTE if !$config{$arg};

    if (!-f $config{$arg}) {
        if (open my $un, '>', $config{$arg}) {
            close $un;
            print "Created empty '$config{$arg}'...\n";
        }
        else {
            print "Error creating '$config{$arg}': $!\n";
        }
    }

    $arg = 'un_position';
    $config{$arg} = prompt($arg);
}

=item force_c_locale

C<force_c_locale> is passed as a switch to F<mktest.pl> to indicate that
C<$ENV{LC_ALL}> should be forced to "C" during B<make test>.

=cut

unless ( $config{is56x} ) {
    $arg = 'force_c_locale';
    $config{ $arg } = prompt_yn( $arg );
}

=item defaultenv

C<defaultenv>, when set will make Test::Smoke remove $ENV{PERLIO} and
only do a single pass C<< S<make test> >>.

=cut

$arg = 'defaultenv';
if ( $config{is56x} ) {
    $config{ $arg } = 1;
} else {
    $config{ $arg } = prompt_yn( $arg );
    if ( is_win32 && ! $config{ $arg } ) {
        print "*** WHOA THERE!!! ***\n";
        print "\tYou should not try to use PERLIO=stdio on MSWin32!\n";
    }
}
=item locale

C<locale> and its value are passed to F<mktest.pl> and its value is passed
to F<mkovz.pl>. F<mktest.pl> will do an extra pass of B<make test> with
C<< $ENV{LC_ALL} >> set to that locale (and C<< $ENV{PERL_UNICODE} = ""; >>,
C<< $ENV{PERLIO} = "perlio"; >>). This feature should only be used with
UTF8 locales, that is why this is checked (by regex only).

B<If you know of a way to get the utf8 locales on your system, which is
not covered here, please let me know!>

=cut

UTF8_LOCALE: {
    last if $config{defaultenv};
    my @locale_utf8 = $config{is56x} ? () : check_locale();
    last UTF8_LOCALE unless @locale_utf8;

    my $list = join " |", @locale_utf8;
    format STDOUT =
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~
$list
.
    local $: = "|";
    $arg = 'locale';
    print "\nI found these UTF-8 locales:\n";
    write;
    $config{ $arg } = prompt( $arg );
}

=item smokedb_url [http://perl5.test-smoke.org]

Instead of flooding a mailing list, reposts should be sent to the SmokeDB.
The option to mail yourself a copy of the report still exists. The SmokeDB
however offers a central point of view to the smoke results.

=item send_log <always|on_fail|never> [on_fail]

Please send in the smoke-logfile for failures.

=item send_out <always|on_fail|never> [never]

=cut

SMOKEDB: {
    eval q{require JSON;};
    my $has_json = !$@;
    if ( !$has_json ) {
        $config{smokedb_url} = $config{poster} = "";
        print "Could not find 'JSON', please install.\n";
        last SMOKEDB;
    }

    if (!@{ $opt{poster}{alt} }) {
        $config{smokedb_url} = $config{poster} = "";
        print "Could not find a HTTP poster, no CoreSmokeDB.\n";
        last SMOKEDB;
    }

    $arg = 'smokedb_url';
    $config{ $arg } = prompt( $arg );
    if (! $config{$arg}) {
        $config{smokedb_url} = $config{poster} = "";
        last SMOKEDB;
    }

    $arg = 'poster';
    $config{$arg} = prompt($arg);
    if (! $config{$arg}) {
        $config{smokedb_url} = $config{poster} = "";
        last SMOKEDB;
    }
    $config{curlbin} = whereis('curl') if $config{poster} eq 'curl';

    $arg = 'send_log';
    $config{ $arg } = prompt( $arg );

    $arg = 'send_out';
    $config{ $arg } = prompt( $arg );

    $arg = 'ua_timeout';
    $config{$arg} = $opt{$arg}{dft};
}

=item mail

C<{mail}> will set the new default for L<tssmokeperl.pl>

=item mail_type

See L<Test::Smoke::Mailer> and L<mailrpt.pl>

=cut

$arg = 'mail';
$opt{ $arg }{dft} = ! $options{usedft};
$config{ $arg } = prompt_yn( $arg );
MAIL: {
    last MAIL unless $config{mail};
    print "The order of the mail questions has been changed!\n";

    $arg = 'mail_type';
    $config{ $arg } = prompt( $arg );

    $arg = 'to';
    while ( !$config{ $arg } ) { $config{ $arg } = prompt( $arg ) }

    MAILER: {
        local $_ = $config{mail_type};

        /^mailx$/          && do {
            if ( $config{bcc} ) {
                $arg = 'swbcc';
                $config{ $arg } = prompt( $arg );
            }
            last MAILER;
        };
        /^mail$/           && do { last MAILER };
        /^sendmail$/       && do {
            $arg = 'from';
            $config{ $arg } = prompt( $arg );
        };

        /^sendemail$/       && do {
            $arg = 'from';
            $config{ $arg } = prompt( $arg );

            $arg = 'mserver';
            $config{ $arg } = prompt( $arg );

            $arg = 'muser';
            $config{ $arg } = prompt( $arg );

            $arg = 'mpass';
            $config{ $arg } = prompt( $arg );
        };

        /^(?:Mail::Sendmail|MIME::Lite)$/ && do {
            $arg = 'from';
            $opt{ $arg }{chk} = '\S+';
            $config{ $arg } = prompt( $arg );

            $arg = 'mserver';
            $config{ $arg } = prompt( $arg );
        };
    }
    $arg = 'ccp5p_onfail';
    $config{ $arg } = prompt_yn( $arg );

    $arg = 'cc';
    $config{ $arg } = prompt( $arg );

    $arg = 'bcc';
    $config{ $arg } = prompt( $arg );

    if ( $config{mail_type} eq 'mailx' &&
         ( $config{cc} || $config{ccp5p_onfail} ) ) {
        $arg = 'swcc';
        $config{ $arg } = prompt( $arg );
    }
}

=item w32args

For MSWin32 we need some extra information that is passed to
L<Test::Smoke::Smoker> in order to compensate for the lack of
B<Configure>.

See L<Test::Smoke::Util/"Configure_win32( )"> and L<W32Configure.pl>

=cut

WIN32: {
    last WIN32 unless is_win32;

    my $osvers = get_Win_version();
    my %compilers = get_avail_w32compilers();

    my $dft_compiler = $conf->{w32cc} ? $conf->{w32cc} : "";
    $dft_compiler ||= ( sort keys %compilers )[-1];
    $opt{w32cc} = {
        msg => 'What compiler should be used?',
        alt => [ keys %compilers ],
        dft => $dft_compiler,
    };

    print <<EO_MSG;

I see you are on $^O ($osvers).
No problem, but we need extra information.
EO_MSG

    $config{w32cc} = uc prompt( 'w32cc' );

    $opt{w32make} = {
        alt => $compilers{ $config{w32cc} }->{maker},
        dft => ( sort @{ $compilers{ $config{w32cc} }->{maker} } )[-1],
    };
    $opt{w32make}->{msg} = @{ $compilers{ $config{w32cc} }->{maker} } > 1
        ? "Which make should be used" : undef;

    $config{w32make} = prompt( 'w32make' );
    $config{testmake} = $config{testmake};

    $config{w32args} = [
        "--win32-cctype" => $config{w32cc},
        "--win32-maker"  => $config{w32make},
        "osvers=$osvers",
        $compilers{ $config{w32cc} }->{ccversarg},
    ];
}

=item vmsmake

Get the make program to use for VMS (MMS or MMK). Start with the one
this perl was build with.

=cut

VMSMAKE: {
    is_vms or last VMSMAKE;

    my %vmsmakers = get_avail_vms_make();

    $arg = 'vmsmake';
    $opt{ $arg } = {
        msg => "Wich maker should be used?",
        alt => [ sort keys %vmsmakers ],
        dft => ( $Config{make} || (sort keys %vmsmakers)[0] ),
    };
    $config{ $arg } = prompt( $arg );
    $config{testmake} = $config{ $arg }
}

=item make finetuning

Two different config options to accomodate the same thing:
I<parallel build> and I<serial testing>

  * makeopt  => used by Test::Smoke::Smoker::_make()
  * testmake => use a different binary for "make _test"

=cut

$arg = 'makeopt';
$opt{ $arg }->{dft} = '-nologo' if is_win32 && $config{w32make} =~ /nmake/i;
$config{ $arg } = prompt( $arg );

unless ( is_win32 || is_vms ) {
    $arg = 'testmake';
    $config{ $arg } = prompt( $arg ) || 'make';
}

=item harnessonly

C<harnessonly> indicates that C<make test> is replaced by C<make
test_harness>.

=cut

$arg = 'harnessonly';
$config{ $arg } = prompt_yn( $arg );

=item hasharness3

C<hasharness3> is automagically set for perl version >= 5.11

=cut

$config{hasharness3} = $config{perl_version} eq 'blead'
                    || _perl_numeric_version( $config{perl_version} ) > 5.01001;

=item harness3opts

C<harness3opts> are passed to C<HARNESS_OPTIONS> for the C<make
test_harness> step.

=cut

if ( ($config{harnessonly} || is_win32) && $config{hasharness3} ) {
    $arg = 'harness3opts';
    $config{ $arg } = prompt( $arg );
}

=item umask

C<umask> will be set in the shell-script that starts the smoke.

=item renice

C<renice> will add a line in the shell-script that starts the smoke.

=cut

unless ( is_win32 || is_vms ) {
    $arg = 'umask';
    $config{ $arg } = prompt( $arg );

    $arg = 'renice';
    $config{ $arg } = prompt( $arg );
}

=item v

The verbosity level:

=over 8

=item 0: Be as quiet as possible

=item 1: Give moderate information

=item 2: Be as loud as possible

=back

Every module has its own verbosity control and these are not verry
consistent at the moment.

=cut

$arg = 'v';
$config{ $arg } = prompt( $arg );

=item smartsmoke

C<smartsmoke> indicates that the smoke need not happen if the patchlevel
is the same after syncing the source-tree.

=cut

$arg = 'smartsmoke';
$config{ $arg } = prompt_yn( $arg );

=item killtime

When C<< $Config{d_alarm} >> is found we can use C<alarm()> to abort
long running smokes. Leave this value empty to keep the old behaviour.

    07:30 => F<tssmokeperl.pl> is aborted on 7:30 localtime
   +23:45 => F<tssmokeperl.pl> is aborted after 23 hours and 45 minutes

Thank you Jarkko for donating this suggestion.

=cut

if ( $Config{d_alarm} ) {
    $arg = 'killtime';
    $config{ $arg } = prompt( $arg );
}

=item adir

The smokereports are lost after a new SYNCTREE step, it might be handy
to archive them along with the logfile.

If you want this then set the directory where you want the stored
(empty value means no archiving).

=cut

$arg = 'adir';
( my $pver_nodot = $config{perl_version} ) =~ tr/.//d;
my $adirsuf = $options{'prefix'} || $pver_nodot;
$opt{ $arg }->{dft} = File::Spec->catdir( 'logs', $adirsuf );
$config{ $arg } = prompt_dir( $arg );
$config{lfile} = File::Spec->rel2abs( $options{log}, cwd );

=item delay_report

Some filesystems do not support opening an already opened file. This
makes it hard to scan the logfile for compiler messages. We can delay
the creation of the report and call F<mailrpt.pl> after
F<tssmokeperl.pl>. VMS might benefit.

=cut

$arg = 'delay_report';
$config{ $arg } = $^O =~ /VMS/;

=item PERL5LIB

If you have a value for PERL5LIB set in the config environment, you
could have it transferred tho the jcl-wrapperscript. Do not bother
asking if it is not there.

=cut

my $has_perl5lib = exists $ENV{PERL5LIB} && defined $ENV{PERL5LIB} &&
                   length $ENV{PERL5LIB};

P5LIB: {
    $has_perl5lib or last P5LIB;
    print "\nI see you have PERL5LIB set to: '$ENV{PERL5LIB}'";
    $arg = 'perl5lib';
    $config{ $arg } = prompt( $arg );
}

=item PERL5OPT

If you have a value for PERL5OPT set in the config environment, you
could have it transferred tho the jcl-wrapperscript. Do not bother
asking if it is not there.

=cut

my $has_perl5opt = exists $ENV{PERL5OPT} && defined $ENV{PERL5OPT} &&
                   length $ENV{PERL5OPT};

P5OPT: {
    $has_perl5opt or last P5OPT;
    print "\nI see you have PERL5OPT set to: '$ENV{PERL5OPT}'";
    $arg = 'perl5opt';
    $config{ $arg } = prompt( $arg );
}

=item schedule stuff

=over 4

=item cron/crontab

We try to detect 'crontab' or 'cron', read the contents of
B<crontab -l>, detect ourself and comment us out.
Then we add an new entry.

=item MSWin32 at.exe

We only add a new entry, you will need to remove existing entries,
as F<at.exe> has not got a way comment-out entries.

=back

=cut

my( $cron, $has_crond,  $crontime );
SCHEDULE: {
    is_vms and last SCHEDULE;
    ( $cron, $has_crond ) = get_avail_scheduler();

    last SCHEDULE unless $cron;

    print "\nFound '$cron' as your scheduler";
    print "\nYou do not seem to be running 'cron' or 'crond'"
        unless is_win32 || $has_crond;
    my $do_schedule = prompt_yn( 'docron' );
    last SCHEDULE unless $do_schedule;

    $opt{crontime}->{dft} = sprintf "%02d:%02d", rand(24), rand(60);
    $crontime = prompt( 'crontime' );

    my( @current_cron, $new_entry );
    local *CRON;
    if ( open CRON, is_win32 ? "$cron |" : "$cron -l |" ) {
        @current_cron = <CRON>;
        close CRON or warn "Error reading schedule\n";
    }

    my $cron_smoke = "crontab.smoke";
    # we might need some cleaning
    if ( is_win32 ) {
        @current_cron = grep /^\s+\d+\s+.+\d+:\d+\s/ => @current_cron;

        my $jcl = File::Spec->rel2abs( "$options{jcl}.cmd" );
        $new_entry = schedule_entry( $jcl, $cron, $crontime );

    } else { # Filter out the BSDish "DO NOT EDIT..." lines
        if ( "@current_cron" =~ /^# DO NOT EDIT THIS FILE/ ) {
            splice @current_cron, 0, 3;
        }
        foreach ( @current_cron ) {
            s/^(?<!#)(\d+.+(?:$options{jcl}|smoke)\.sh)/#$1/;
        }

        my $jcl = File::Spec->rel2abs( "$options{jcl}.sh" );
        $new_entry = schedule_entry( $jcl, $cron, $crontime );
        if ( open CRON, "> $cron_smoke" ) {
            print CRON @current_cron, "$new_entry\n";
            close CRON or warn "Error while writing '$cron_smoke': $!";
        }

    }

    print "I will use this to add to:\n", @current_cron;
    $opt{add2cron} = {
        msg => "Add this line to your schedule?\n\t$new_entry\n",
        alt => [qw( Y n )],
        dft => 'y',
    };
    my $add2cron = prompt_yn( 'add2cron' );
    if ( !is_win32 && !$add2cron ) {
        print "\nLeft '$cron_smoke' in case you want to use it.\n";
    }
    last SCHEDULE unless $add2cron;

    if ( is_win32 ) {
        system $new_entry;
    } else {
        my $nok = system $cron, $cron_smoke;
        if ( $nok ) {
            print "\nCouldn't set new crontab\nLeft '$cron_smoke'\n";
        } else {
            unlink $cron_smoke;
        }
    }
}

my $jcl;
SAVEALL: {
    save_config();
    if ( is_win32 ) {
        $jcl = write_bat();
    } elsif ( is_vms ) {
        $jcl = write_com();
    } else {
        $jcl = write_sh();
    }
}

WRAPUP: {
    local $" = "";
    my $chkbcfg = File::Spec->catfile( $FindBin::Bin, 'chkbcfg.pl' );
    print <<EOMSG;
Finished configuration:

* Please check "$config{cfg}" for the
  configurations you want to test:
@{ [map "    $_" => qx( $^X $chkbcfg $config{cfg} )] }

* Run the perl core test smoke suite with:
\t$jcl

* Have the appropriate amount of fun!

                                    The Test::Smoke team.
EOMSG
}

=back

=head1 Supporting subs

=over 4

=item save_config()

C<save_config()> writes the configuration data to disk.
If C<< Data::Dumper->can('Sortkeys') >> it will order the keys.

=cut

sub save_config {
    my $dumper = Data::Dumper->new([ \%config ], [ 'conf' ]);
    Data::Dumper->can( 'Sortkeys' ) and
        $dumper->Sortkeys( \&sort_configkeys );
    local *CONFIG;
    open CONFIG, "> $options{config}" or
        die "Cannot write '$options{config}': $!";
    print CONFIG $dumper->Dump;
    close CONFIG or warn "Error writing '$options{config}': $!" and return;

    print "Finished writing '$options{config}'\n";
}

=item sort_configkeys()

C<sort_configkeys()> is the hook for B<Data::Dumper>

Order and grouping by Merijn, thanks!

=cut

sub sort_configkeys {
    my @order = (
        # Test::Smoke (startup) related
        qw( cfg v smartsmoke renice killtime umask ),

        # Perl dist related
        qw( perl_version is56x ddir ),

        # Sync related
        qw( sync_type fsync rsync opts source tar server sdir sfile
            unzip patchbin cleanup cdir hdir pfile
            gitbin gitdir gitorigin gitdfbranch gitbranchfile ),

        # OS specific make related
        qw( w32args w32cc w32make ),

        # Test environment related
        qw( force_c_locale locale defaultenv ),

        # Report related
        qw( mail mail_type mserver muser mpass from to ccp5p_onfail
            swcc cc swbcc bcc ),

        #SmokeDB
        qw( smokedb_url send_log send_out ua_timeout ),

        # Archive reports and logfile
        qw( adir lfile ),

        # make fine-tuning
        qw( makeopt testmake harnessonly hasharness3 harness3opts ),

        # user_notes
        qw( hostname user_note un_file un_position ),

        # ENV stuff
        qw( perl5lib delay_report ),
    );

    my $i = 0;
    my %keyorder = map { $_ => $i++ } @order;

    my @keyord = sort {
        $a <=> $b
    } @keyorder{ grep exists $keyorder{ $_}, keys %{ $_[0] } };

    return [ @order[ @keyord ],
             sort grep !exists $keyorder{ $_ }, keys %{ $_[0] } ];
}

=item write_sh()

C<write_sh()> creates the shell-script.

=cut

sub write_sh {
    my $cwd = cwd();
    my $jcl = "$options{jcl}.sh";
    my $smokeperl = File::Spec->catfile( $FindBin::Bin, 'tssmokeperl.pl' );
    my $cronline = schedule_entry( File::Spec->catfile( $cwd, $jcl ),
                                   $cron, $crontime );

    my $p5lib = $config{perl5lib} ? <<EO_P5LIB : '';
PERL5LIB=$config{perl5lib}
export PERL5LIB
EO_P5LIB
    my $p5opt = $config{perl5opt} ? <<EO_P5OPT : '';
PERL5OPT=$config{perl5opt}
export PERL5OPT
EO_P5OPT

    my $handle_lock = $config{killtime} ? <<EO_CONT : <<EO_DIE;
    # Not sure about this, so I will keep the old behaviour
    # tssmokeperl.pl will exit(42) on timeout
    # continue='--continue'
    echo "We seem to be running (or remove \$LOCKFILE)" >& 2
    exit 200
EO_CONT
    echo "We seem to be running (or remove \$LOCKFILE)" >& 2
    exit 200
EO_DIE

    local *MYSMOKESH;
    open MYSMOKESH, "> $jcl" or
        die "Cannot write '$jcl': $!";
    print MYSMOKESH <<EO_SH;
#! /bin/sh
#
# Written by $0 v$VERSION
# @{[ scalar localtime ]}
# NOTE: Changes made in this file will be \*lost\*
#       after rerunning $0
#
# $cronline
@{[ renice( $config{renice} ) ]}
cd $cwd
CFGNAME=\${CFGNAME:-$options{config}}
LOCKFILE=\${LOCKFILE:-$options{prefix}.lck}
continue=''
if test -f "\$LOCKFILE" && test -s "\$LOCKFILE" ; then
$handle_lock
fi
echo "\$CFGNAME" > "\$LOCKFILE"

$p5lib
PATH=$FindBin::Bin:$ENV{PATH}
export PATH
umask $config{umask}
$^X $smokeperl -c "\$CFGNAME" \$continue \$\* > $options{log} 2>&1

rm "\$LOCKFILE"
EO_SH
    close MYSMOKESH or warn "Error writing '$jcl': $!";

    chmod 0755, $jcl or warn "Cannot chmod 0755 $jcl: $!";
    print "Finished writing '$jcl'\n";

    return File::Spec->canonpath( File::Spec->rel2abs( $jcl ) );
}

=item write_bat()

C<write_bat()> writes the batch-file. It uses the C<.cmd> extension
because it uses commands that are not supported by B<COMMAND.COM>

=cut

sub write_bat {
    my $cwd = File::Spec->canonpath( cwd() );
    my $findbin_bin = File::Spec->canonpath( $FindBin::Bin );

    my $smokeperl  = File::Spec->catfile( $findbin_bin, 'tssmokeperl.pl' );
    my $archiverpt = File::Spec->catfile( $findbin_bin, 'tsarchive.pl' );
    my $mailrpt    = File::Spec->catfile( $findbin_bin, 'tssendrpt.pl' );
    my $copycmd = <<'EOCOPYCMD';

REM I found hanging XCOPY while smoking; uncommenting the next line might help
REM set COPYCMD=/Y \%COPYCMD\%

EOCOPYCMD
    my $p5lib = $config{perl5lib} ? <<EO_P5LIB : '';

set PERL5LIB=$config{perl5lib}
EO_P5LIB
    my $p5opt = $config{perl5opt} ? <<EO_P5OPT : '';

set PERL5OPT=$config{perl5opt}
EO_P5OPT


    my $jcl = "$options{jcl}.cmd";
    my $atline = schedule_entry( File::Spec->catfile( $cwd, $jcl ),
                                 $cron, $crontime );

    my $archive = qq/$^X $archiverpt -c "\%CFGNAME\%"/;
    $config{lfile} or $archive =~ s/^/REM /;

    my $report = qq/$^X $mailrpt -c "\%CFGNAME\%"/;
    $config{delay_report} or $report =~ s/^/REM /;

    local *MYSMOKEBAT;
    open MYSMOKEBAT, "> $jcl" or
        die "Cannot write '$jcl': $!";
    print MYSMOKEBAT <<EO_BAT;
\@echo off
setlocal

REM Written by $0 v$VERSION
REM @{[ scalar localtime ]}
REM NOTE: Changes made in this file will be \*lost\*
REM       after rerunning $0
$copycmd
$p5lib
REM $atline

set WD=$cwd\\
rem Change drive-Letter
for \%\%L in ( "\%WD\%" ) do \%\%~dL
cd "\%WD\%"
if "\%CFGNAME\%"  == "" set CFGNAME=$options{config}
if "\%LOCKFILE\%" == "" set LOCKFILE=$options{prefix}.lck
if NOT EXIST \%LOCKFILE\% goto START_SMOKE
    FIND "\%CFGNAME\%" \%LOCKFILE\% > NUL:
    if ERRORLEVEL 1 goto START_SMOKE
    echo We seem to be running [or remove \%LOCKFILE\%]>&2
    goto :EOF

:START_SMOKE
    echo \%CFGNAME\% > \%LOCKFILE\%
    set OLD_PATH=\%PATH\%
    set PATH=$findbin_bin;\%PATH\%
    $^X $smokeperl -c "\%CFGNAME\%" \%* > "\%WD\%\\$options{log}" 2>&1
    REM $report
    REM $archive
    set PATH=\%OLD_PATH\%

del \%LOCKFILE\%
EO_BAT
    close MYSMOKEBAT or warn "Error writing '$jcl': $!";

    print "Finished writing '$jcl'\n";

    return File::Spec->canonpath( File::Spec->rel2abs( $jcl ) );
}

=item write_com

Write a simple DCL script that helps running the smoke suite.

=cut

sub write_com {
    my $jcl = "$options{jcl}.com";
    my $cwd = File::Spec->canonpath( cwd() );
    my $p5lib_p = $config{perl5lib} ? ' '  : '!';
    my $p5lib = "$p5lib_p DEFINE PERL5LIB $config{perl5lib}";
    my $p5opt_p = $config{perl5opt} ? ' '  : '!';
    my $p5opt = "$p5opt_p DEFINE PERL5OPT $config{perl5opt}";
    local *MYSMOKECOM;
    open MYSMOKECOM, "> $jcl" or
        die "Cannot write '$jcl': $!";
    print MYSMOKECOM <<EO_COM;
\$! $jcl - Run Perl5 core test smoke suite
\$!
\$! Written by $0 v$VERSION
\$! @{[ scalar localtime ]}
\$! NOTE: Changes made in this file will be \*lost\*
\$!       after rerunning $0
\$! Try:
\$!       SUBMIT/NOPRINTER/NOTIFY $cwd$jcl
\$!
\$  SET DEFAULT $cwd
\$$p5lib
\$$p5opt
\$! DEFINE/USER sys\$output $options{log}
\$! DEFINE/USER sys\$error $options{log}
\$  MCR $^X ${FindBin::Bin}/tssmokeperl.pl "-c=$options{config}"
EO_COM
    close MYSMOKECOM or warn "Error writing '$jcl': $!";

    print "Finished writing '$jcl'\n";

    return '@' . File::Spec->canonpath( File::Spec->rel2abs( $jcl ) );
}

sub prompt {
    my( $message, $alt, $df_val, $chk, $nck ) =
        @{ $opt{ $_[0] } }{qw( msg alt dft chk nck )};

    $df_val = $conf->{ $_[0] } if exists $conf->{ $_[0] };
    $df_val = $conf->{ $_[1] } if $_[1] && exists $conf->{ $_[1] };
    unless ( defined $message ) {
        my $retval = defined $df_val ? $df_val : "undef";
        (caller 1)[3] or print "Got [$retval]\n";
        return $df_val;
    }

    $message =~ s/\s+$//;

    my %ok_val;
    %ok_val = map { (lc $_ => 1) } @$alt if @$alt;
    $chk ||= '.*';

    my $default = defined $df_val ? $df_val : 'undef';
    if ( @$alt && defined $df_val ) {
        $default = $df_val = $alt->[0] unless exists $ok_val{ lc $df_val };
    }
    my $alts    = @$alt ? "<" . join( "|", @$alt ) . "> " : "";
    print "\n$message\n";

    my( $input, $clear );
    INPUT: {
        if ( $options{usedft} ) {
            $input = defined $df_val ? $df_val : " ";
        } else {
            print "$alts\[$default] \$ ";
            chomp( $input = <STDIN> );
        }
        if ( $input eq " " ) {
            $input = "";
            $clear = 1;
        } elsif ( $input eq '&-d' ) {
            $options{usedft} = 1;
            print "(OK, We'll run with --des from now on.)\n";
            redo INPUT;
        } else {
            $input =~ s/^\s+//;
            $input =~ s/\s+$//;
            $input = $df_val unless length $input;
        }

        print "Input should not match: '/$nck/i'\n" and redo INPUT
            if $nck && $input =~ m/$nck/i;

        print "Input does not match: 'm/$chk/'\n" and redo INPUT
            unless $input =~ m/$chk/i;

        last INPUT unless %ok_val;
        printf "Expected one of: '%s'\n", join "', '", @$alt and redo INPUT
            unless exists $ok_val{ lc $input };

    }

    my $retval = length $input ? $input : $clear ? "" : $df_val;
    (caller 1)[3] or print "Got [$retval]\n";
    return $retval;
}

sub chk_dir {
    my( $dir ) = @_;
    defined $dir or return;
    my $cwd = cwd();
    File::Path::mkpath( $dir, 1, 0755 ) unless -d $dir;

    if ( ! chdir $dir  ) {
        warn "Cannot chdir($dir): $!\n";
        $dir = undef;
    } else {
        $dir = File::Spec->canonpath( cwd() );
    }
    chdir $cwd or die "Cannot chdir($cwd) back: $!";

    return $dir;
}

sub prompt_dir {

    if ( exists $conf->{ $_[0] } && $conf->{ $_[0] } )  {
        $conf->{ $_[0] } = File::Spec->rel2abs( $conf->{ $_[0] } )
            unless File::Spec->file_name_is_absolute( $conf->{ $_[0] } );
    }

    GETDIR: {


        my $dir = prompt( @_ );
        if ( $dir eq "" && ! @{ $opt{ $_[0] }->{alt} } &&
             ! $opt{ $_[0] }->{chk} ) {
            print "Got []\n";
            return "";
        }

        # thanks to perlfaq5
        $dir =~ s{^ ~ ([^/]*)}
                 {$1 ? ( getpwnam $1 )[7] :
                       ( $ENV{HOME} || $ENV{LOGDIR} ||
                         "$ENV{HOMEDRIVE}$ENV{HOMEPATH}" )}ex;

        defined( $dir = chk_dir( $dir ) ) or redo GETDIR;

        print "Got [$dir]\n";
        return $dir;
    }
}

sub prompt_file {
    my( $arg, $no_valid ) = @_;

    GETFILE: {
        my $file = prompt( $arg );


        # thaks to perlfaq5
        $file =~ s{^ ~ ([^/]*)}
                  {$1 ? ( getpwnam $1 )[7] :
                   ( $ENV{HOME} || $ENV{LOGDIR} ||
                   "$ENV{HOMEDRIVE}$ENV{HOMEPATH}" )}ex;
        $file = File::Spec->rel2abs( $file ) unless !$file && $no_valid;

        print "'$file' does not exist: $!\n" and redo GETFILE
            unless -f $file || $no_valid;

        printf "Got[%s]\n", defined $file ? $file : 'undef';
        return $file;
    }
}

sub prompt_yn {
    my( $arg ) = @_;

    $opt{ $arg }{dft} ||= "0";
    $opt{ $arg }{dft} =~ tr/01/ny/;
    if ( exists $conf->{ $arg } ) {
        $conf->{ $arg } ||= "0";
        $conf->{ $arg } =~ tr/01/ny/;
    }

    my $yesno = lc prompt( $arg );
    print "Got [$yesno]\n";
    ( my $retval = $yesno ) =~ tr/ny/01/;
    return $retval;
}

sub find_a_patch {
    return (get_avail_patchers())[0];
}

sub renice {
    my $rn_val = shift;

    return $rn_val ? <<EORENICE : <<EOCOMMENT
# Run renice:
(renice -n $rn_val \$\$ >/dev/null 2>&1) || (renice $rn_val \$\$ >/dev/null 2>&1)
EORENICE
# Uncomment this to be as nice as possible. (Jarkko)
# (renice -n 20 \$\$ >/dev/null 2>&1) || (renice 20 \$\$ >/dev/null 2>&1)
EOCOMMENT

}

sub check_locale {
    # I only know one way... and one for Darwin (perhaps FreeBSD)
    if ( $^O =~ /darwin|bsd/i ) {
        local *USL;
        opendir USL, '/usr/share/locale' or return;
        my @list = grep /utf-?8$/i => readdir USL;
        closedir USL;
        return @list;
    }
    my $locale = whereis( 'locale' );
    return unless $locale;
    return grep /utf-?8$/i => split /\n/, `$locale -a`;
}

sub get_avail_scheduler {
    my( $scheduler, $crond );
    if ( is_win32 ) { # We're looking for 'at.exe'
        $scheduler = whereis( 'at' );
    } else { # We're looking for 'crontab' or 'cron'
        $scheduler = whereis( 'crontab' ) || whereis( 'cron' );
        ( $crond ) = grep /\bcrond?\b/ => `ps -e`;
    }
    return ( $scheduler, $crond );
}

sub schedule_entry {
    my( $script, $cron, $crontime ) = @_;

    return '' unless $crontime;
    my( $hour, $min ) = $crontime =~ /(\d+):(\d+)/;

    my $entry;
    if ( is_win32 ) {
        $entry = sprintf qq[$cron %02d:%02d /EVERY:M,T,W,Th,F,S,Su "%s"],
                 $hour, $min, $script;
    } else {
        $entry = sprintf qq[%02d %02d * * * '%s'], $min, $hour, $script;
    }
    return $entry;
}

sub get_Win_version {
    require System::Info::Windows;
    my $si = System::Info::Windows->new();
    (my $win_version = $si->os) =~ s/^[^-]*- //;
    return $win_version;
}

=item default_buildcfg( $file_name, $pversion )

Check to see if C<$file_name> exists. If not, copy the default config
for C<$pversion> to C<$file_name>.

=cut

sub default_buildcfg {
    my( $file_name, $pversion ) = @_;
    -f $file_name and return 1;

    $pversion =~ tr/.//d;
    my $is_devel = $pversion =~ /^5\d+[13579]x$/;
    $pversion = $is_devel ? 'current' : 'maint';
    my $basename = is_win32
        ? "w32current.cfg"
        : is_vms ? "vmsperl.cfg" : "perl${pversion}.cfg";

    my $dftbcfg;
    for my $dir ( @INC ) {
        my $ts_dir = File::Spec->catdir( $dir, 'Test', 'Smoke' );
        $dftbcfg = File::Spec->catfile( $ts_dir, $basename );
        -f $dftbcfg and last;
    }
    -f $dftbcfg
        or die "You seem to have an incomplete Test::Smoke installation" .
               "($basename is missing)!\n";
    copy $dftbcfg, $file_name
        and print "\nCreated buildconfig '$file_name'";
}

=item check_buildcfg

We will try to check the build configurations file to see if we should
comment some options out.

=cut

sub check_buildcfg {
    my( $file_name ) = @_;

    local *BCFG;
    open BCFG, "< $file_name" or do {
        warn "Cannot read '$file_name': $!\n" .
             "Will not check the build configuration file!";
        return;
    };
    my @bcfg = <BCFG>;
    close BCFG;
    my $oldcfg = join "", grep !/^#/ => @bcfg;

    my $pversion = $config{perl_version} =~ /^5\./
        ? _perl_numeric_version( $config{perl_version} )
        : $config{perl_version};

    my $uname_s = System::Info::si_uname( 's' );
    my( $os, $osver ) = split /\s+-\s+/, $uname_s;
    # May assume much too much about OS version number formats.
    my( $osvermaj, $osvermin ) = ($osver =~ /^\D*(\d+)\D+(\d+)/);
    $osver = sprintf "%s", $osvermaj || '?';
    defined $osvermin and $osver .= sprintf ".%03d", $osvermin;


    print "Checking '$file_name'\n     for $pversion on $uname_s\n";

    my @no_option = ($pversion eq 'blead') ||($pversion >= 5.009)
        ? ( '-Uuseperlio' )
        : ( );
    OSCHECK: {
        $os =~ /darwin/ && $osver >= 8 and do {
            push @no_option, qw( -Duselongdouble -Dusemorebits );
            last OSCHECK;
        };

        $os =~ /darwin|bsd/i && do {
            push @no_option, qw( -Duselongdouble -Dusemorebits -Duse64bitall );
        };

        $os =~ /linux/i && do {
            push @no_option, qw( -Duse64bitall );
        };

        $os =~ /mswin32/i && do {
            push @no_option, qw( -Duselargefiles ) if $config{is56x};
        };

        $os =~ /cygwin/i && do {
            push @no_option, qw( -Duse64bitall -Duselongdouble -Dusemorebits );
        };
    }

    foreach my $option ( @no_option ) {
        !/^#/ && /\Q$option\E/ && s/^/#/ for @bcfg;
    }

    my $newcfg = join "", grep !/^#/ => @bcfg;
    return if $oldcfg eq $newcfg;

    my $options = join "|", map "\Q$_\E" => sort {
        length( $b||"" ) <=> length( $a||"" )
    } @no_option;

    my $display = join "", map "\t$_"
        => grep !/^#/ || ( /^#/ && /$options/ ) => @bcfg;
    $opt{change_cfg}->{msg} = <<EOMSG;
Some options that do not apply to your platform were found.
(Comment-lines left out below, but will be written to disk.)
$display
Write the changed config to disk?
EOMSG

    my $write_it = prompt_yn( 'change_cfg' );
    finish_cfgcheck( $write_it, $file_name, \@bcfg);
}

=item finish_cfgcheck

C<finish_cfgcheck()> will create a backup of the original file and
write the new one in its place.

=cut

sub finish_cfgcheck {
    my( $overwrite, $fname, $bcfg ) = @_;

    my $msg = "";
    if ( $overwrite ) {
        my $backup = "$fname.bak";
        -f $backup and chmod( 0775, $backup ) and 1 while unlink $backup;
        rename $fname, $backup or
            warn "Cannot rename '$fname' to '$backup': $!";
    } else {
        $fname = "$options{prefix}.cfg.save";
        $msg = " (in case you want it later)";
    }
    # change the filemode (make install used to make perlcurrent.cfg readonly)
    -f $fname and chmod 0775, $fname;
    open BCFG, "> $fname" or do {
        warn "Cannot write '$fname': $!";
        return;
    };
    print BCFG @$bcfg;
    close BCFG or do {
        warn "Error on close '$fname': $!";
        return;
    };
    print "Wrote '$fname'$msg\n";
}

=item _perl_numeric_version( $dotted )

Normalize the dotted version to a numeric version.

=cut

sub _perl_numeric_version {
    my $dotted = shift;
    my ($rev, @vparts ) = $dotted =~ /^(\d)(?:\.(\d+))+/;
    return sprintf "%d.%03d%02d", $rev, @vparts, 0;
}

=back

=head1 TODO

Schedule, logfile optional

=head1 REVISION

In case I forget to update the C<$VERSION>:

    $Id$

=head1 COPYRIGHT

(c) 2002-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
