package Test::Smoke::App::Options;
use warnings;
use strict;

our $VERSION = '0.002';

use Test::Smoke::App::AppOption;

=head1 NAME

Test::Smoke::App::Options - A collection of application configs and config
options.

=cut

my $opt = 'Test::Smoke::App::AppOption';

sub synctree_config { # synctree.pl
    return (
        main_options => [
            sync_type(),
        ],
        general_options => [
            ddir(),
        ],
        special_options => {
            git  => [
                gitbin(),
                gitorigin(),
                gitdir(),
                gitbare(),
                gitdfbranch(),
                gitbranchfile(),
            ],
            rsync => [
                rsyncbin(),
                rsyncopts(),
                rsyncsource(),
            ],
            copy  => [
                cdir()
            ],
            fsync => [
                fdir(),
            ],
            ftp  => [
                ftphost(),
                ftpport(),
            ],
            snapshot  => [
                snapurl(),
                snaptar(),
            ],
        },
    );
}

sub mailer_config { # mailing reports
    return (
        main_options => [
            mail_type(),
        ],
        general_options => [
            ddir(),
            to(),
            cc(),
            bcc(),
            ccp5p_onfail(),
            rptfile(),
            mail(),
            report(0),
        ],
        special_options => {
            mail => [ mailbin() ],
            mailx => [
                mailxbin(),
                swcc(),
                swbcc(),
            ],
            sendemail => [
                sendemailbin(),
                from(),
                mserver(),
                msport(),
                msuser(),
                mspass(),
            ],
            sendmail => [
                sendmailbin(),
                from(),
            ],
            'Mail::Sendmail' => [
                from(),
                mserver(),
                msport(),
            ],
            'MIME::Lite' => [
                from(),
                mserver(),
                msport(),
                msuser(),
                mspass(),
            ],
        },
    );
}

sub poster_config { # posting to CoreSmokeDB
    return (
        main_options => [
            poster(),
        ],
        general_options => [
            ddir(),
            smokedb_url(),
            jsnfile(),
            qfile(),
            report(0),
        ],
        special_options => {
            'LWP::UserAgent' => [
                ua_timeout(),
            ],
            'HTTP::Tiny' => [
                ua_timeout(),
            ],
            'curl' => [
                curlbin(),
                curlargs(),
                ua_timeout(),
            ],
        },
    );
}

sub reporter_config { # needed for sending out reports
    return (
        general_options => [
            ddir(),
            outfile(),
            rptfile(),
            jsnfile(),
            lfile(),
            cfg(),
            showcfg(),
            locale(),
            defaultenv(),
            perlio_only(),
            is56x(),
            skip_tests(),
            harnessonly(),
            harness3opts(),
            hostname(),
            from(),
            send_log(),
            send_out(),
            user_note(),
            un_file(),
            un_position(),
        ],
    );
}

sub reposter_config {
    my %pc = poster_config();
    my $pc_so = $pc{special_options};
    return (
        main_options => [
            poster(),
        ],
        general_options => [
            adir(),
            commit_sha(),
            jsonreport(),
            max_reports(),
            smokedb_url(),
        ],
        special_options => $pc_so,
    );
}

sub sendreport_config { # sendreport.pl
    # merge: mailer_config, poster_config and reporter_config.
    my %mc = mailer_config();
    my %pc = poster_config();
    my %rc = reporter_config();
    my %g_o;
    for my $opt ( @{$mc{general_options}}
                , @{$pc{general_options}}
                , @{$rc{general_options}})
    {
        $g_o{$opt->name} ||= $opt;
    }
    my %s_o;
    for my $so (keys %{$mc{special_options}}) {
        $s_o{$so} = $mc{special_options}{$so};
    }
    for my $so (keys %{$pc{special_options}}) {
        $s_o{$so} = $pc{special_options}{$so};
    }

    return (
        main_options    => [mail_type(), poster() ],
        general_options => [values %g_o, report(0)],
        special_options => \%s_o,
    );
}

sub runsmoke_config { # runsmoke.pl
    return (
        general_options => [
            ddir(),
            outfile(),
            rptfile(),
            jsnfile(),
            cfg(),
            defaultenv(),
            perlio_only(),
            force_c_locale(),
            harness3opts(),
            harnessonly(),
            hasharness3(),
            is56x(),
            is_vms(),
            is_win32(),
            killtime(),
            locale(),
            makeopt(),
            opt_continue(),
            skip_tests(),
            testmake(),
            w32args(),
            w32cc(),
            w32make(),
            pass_option(),
        ],
    );
}

sub archiver_config {
    return (
        general_options => [
            archive(),
            ddir(),
            adir(),
            outfile(),
            rptfile(),
            jsnfile(),
            lfile(),
        ],
    );
}

sub smokeperl_config {
    my %stc = synctree_config();
    my %rsc = runsmoke_config();
    my %arc = archiver_config();
    my %src = sendreport_config();

    my %m_o;
    for my $opt (@{$stc{main_options}}, @{$rsc{main_options}},
                 @{$arc{main_options}}, @{$src{main_options}})
    {
        $m_o{$opt->name} ||= $opt;
    }
    my %g_o = (
        sync()->name       => sync(),
        report()->name     => report(),
        sendreport()->name => sendreport(),
        archive()->name    => archive(),
        smartsmoke()->name => smartsmoke(),
        patchlevel()->name => patchlevel(),
    );
    for my $opt (@{$stc{general_options}}, @{$rsc{general_options}},
                 @{$arc{general_options}}, @{$src{general_options}})
    {
        $g_o{$opt->name} ||= $opt;
    }
    my %s_o;
    for my $so (keys %{$stc{special_options}}) {
        $s_o{$so} = $stc{special_options}{$so};
    }
    for my $so (keys %{$rsc{special_options}}) {
        $s_o{$so} = $rsc{special_options}{$so};
    }
    for my $so (keys %{$arc{special_options}}) {
        $s_o{$so} = $arc{special_options}{$so};
    }
    for my $so (keys %{$src{special_options}}) {
        $s_o{$so} = $src{special_options}{$so};
    }

    return (
        main_options => [sort { $a->name cmp $b->name } values %m_o],
        general_options => [sort { $a->name cmp $b->name } values %g_o],
        special_options => { %s_o },
    );
}

sub w32configure_config {
    return (
        general_options => [
            ddir(),
            w32cc(),
            w32make(),
            w32args(),
        ],
    );
}

sub configsmoke_config {
    return (
        general_options => [
            minus_des()
        ]
    );
}

sub smokestatus_config {
    return (
        general_options => [
            ddir(),
            outfile(),
            cfg(),
        ],
    );
}

sub handlequeue_config {
    my %pc = poster_config();
    my $pc_so = $pc{special_options};
    return (
        main_options => [ poster() ],
        general_options => [
            adir(),
            smokedb_url(),
            qfile(),
        ],
        special_options => $pc_so,
    );
}

###########################################################
#####              Individual options                 #####
###########################################################

sub adir {
    return $opt->new(
        name => 'adir',
        option => '=s',
        default => '',
        helptext => "Directory to archive the smoker files in.",
        configtext => "Which directory should be used for the archives?
\t(Make empty for no archiving)",
        configtype => 'prompt_dir',
        configdft => sub {
            my $app = shift;
            require File::Spec;
            File::Spec->catdir('logs', $app->prefix);
        },
    );
}

sub archive {
    return $opt->new(
        name => 'archive',
        option => '!',
        default => 1,
        helptext => "Archive the reports after smoking.",
    );
}

sub bcc {
    return $opt->new(
        name       => 'bcc',
        option     => '=s',
        default    => '',
        helptext   => 'Where to send a bcc of the reports.',
        allow      => [ undef, '', qr/@/ ],
        configtype => 'prompt',
        configtext => 'This is the email address used to send BlindCarbonCopy:',
        configdft  => sub {''},
    );
}

sub cc {
    return $opt->new(
        name       => 'cc',
        option     => '=s',
        default    => '',
        helptext   => 'Where to send a cc of the reports.',
        allow      => [ undef, '', qr/@/ ],
        configtype => 'prompt',
        configtext => 'This is the email address used to send CarbonCopy:',
        configdft  => sub {''},
    );
}

sub ccp5p_onfail {
    return $opt->new(
        name => 'ccp5p_onfail',
        option => '!',
        default => 0,
        helptext => 'Include the p5p-mailinglist in CC.',
    );
}

sub cdir { # cdir => ddir
    return $opt->new(
        name => 'cdir',
        option => '=s',
        helptext => "The local directory from where to copy the perlsources.",
    );
}

sub cfg {
    return $opt->new(
        name       => 'cfg',
        option     => '=s',
        default    => undef,
        helptext   => "The name of the BuildCFG file.",
        configtext => "Which build configureations file would you like to use?",
        configtype => 'prompt_file',
        configfnex => 1,
        configdft  => sub {
            my $self = shift;
            use File::Spec;
            File::Spec->rel2abs($self->prefix . ".buildcfg");
        },
    );
}

sub commit_sha {
    return $opt->new(
        name => 'commit_sha',
        option => 'sha=s@',
        allow => sub {
            my $values = shift;
            my $ok = 1;
            $ok &&= m{^ [0-9a-f]+ $}x for @$values;
            return $ok;
        },
        default => [ ],
        helptext => "A (partial) commit SHA (repeatable!)",
    );
}

sub curlargs {
    return $opt->new(
        name     => 'curlargs',
        option   => '=s@',
        default  => [ ],
        helptext => "Extra switches to pass to curl (repeatable!)",
    );
}

sub curlbin {
    return $opt->new(
        name       => 'curlbin',
        option     => '=s',
        default    => 'curl',
        helptext   => "The fqp for the curl program.",
        configtext => "Which 'curl' binary do you want to use?",
        configdft  => sub { (_helper(whereis => ['curl'])->())->[0] },
        configord  => 3,
    );
}

sub ddir {
    return $opt->new(
        name       => 'ddir',
        option     => 'd=s',
        helptext   => 'Directory where perl is smoked.',
        configtext => "Where would you like the new source-tree?",
        configtype => 'prompt_dir',
        configdft  => sub {
            use File::Spec;
            File::Spec->catdir(File::Spec->rel2abs(File::Spec->updir), 'perl-current');
        },
    );
}

sub defaultenv {
    return $opt->new(
        name       => 'defaultenv',
        option     => '!',
        default    => 0,
        helptext   => "Do not set the test suite environment to locale.",
        configtext => "Run the test suite without \$ENV{PERLIO}?",
        configtype => 'prompt_yn',
        configalt  => sub { [qw/ N y /] },
        configdft  => sub {'n'},
    );
}

sub fdir { # mdir => fdir => ddir
    return $opt->new(
        name => 'fdir',
        option => '=s',
        helptext => "The local directory to build the hardlink Forest from.",
    );
}

sub from {
    return $opt->new(
        name       => 'from',
        option     => '=s',
        default    => '',
        allow      => [ '', qr/@/ ],
        helptext   => 'Where to send the reports from.',
        configtype => 'prompt',
        configtext => 'This is the email address used to send FROM:',
        configdft  => sub {''},
    );
}

sub fsync { # How to sync the mdir for Forest.
    my $s = sync_type();
    $s->name('fsync');
    return $s;
}

sub force_c_locale {
    return $opt->new(
        name       => 'force_c_locale',
        default    => 0,
        helptext   => "Run test suite under the C locale only.",
        configtext => "Should \$ENV{LC_ALL} be forced to 'C'?",
        configtype => 'prompt_yn',
        configalt  => sub { [qw/ N y /] },
        configdft  => sub {'n'},
    );
}

sub ftphost {
    return $opt->new(
        name       => 'ftphost',
        option     => '=s',
        default    => 'ftp.example.com',
        helptext   => "The FTP server",
        configtext => "What is the URL of your FTP server?",
        configalt  => sub { [] },
        configord  => 1,
    );
}

sub ftpport {
    return $opt->new(
        name       => 'ftpport',
        option     => '=i',
        default    => 21,
        helptext   => "The FTP port",
        configtext => "What is the port of your FTP server?",
        configalt  => sub { [] },
        configord  => 2,
    );
}

sub snapurl {
    my $blead = "https://github.com/Perl/perl5/archive/refs/heads/blead.tar.gz";
    #my $tag = "https://github.com/Perl/perl5/archive/refs/tags/v5.41.6.tar.gz";
    #my $pr_domestic = "https://github.com/Perl/perl5/archive/refs/pull/22991/head.tar.gz";
    #my $pr_from_fork = "https://github.com/Perl/perl5/archive/refs/pull/22981/head.tar.gz";
    return $opt->new(
        name       => 'snapurl',
        option     => '=s',
        default    => "$blead",
        helptext   => "The URL with path",
        configtext => "What is the URL of the delivery?",
        configalt  => sub { [] },
        configord  => 1,
    );
}

sub snaptar {
    return $opt->new(
        name       => 'snaptar',
        option     => '=s',
        default    => '',
        helptext   => "The tar/zip command to unarchive",
        configtext => "What is the tar/zip command to use to unarchive the delivery?",
        configalt  => sub { [] },
        configord  => 1,
    );
}

sub gitbin {
    return $opt->new(
        name       => 'gitbin',
        option     => '=s',
        default    => 'git',
        helptext   => "The name of the 'git' program.",
        configtext => "Which 'git' binary do you want to use?",
        configtype => 'prompt_file',
        configdft  => sub { (_helper(whereis => ['git'])->())->[0] },
        configord  => 1,
    );
}

sub gitorigin {
    return $opt->new(
        name       => 'gitorigin',
        option     => '=s',
        default    => 'https://github.com/Perl/perl5.git',
        helptext   => "The remote location of the git repository.",
        configtext => "Where is your main Git repository?",
        configalt  => sub { [] },
        configord  => 2,
    );
}

sub gitdir {
    return $opt->new(
        name       => 'gitdir',
        option     => '=s',
        default    => 'perl-from-github',
        helptext   => "The local directory of the git repository.",
        configtext => "Where do I put the main Git repository?",
        configtype => 'prompt_dir',
        configalt  => sub { [] },
        configdft  => sub {
            use File::Spec;
            File::Spec->catfile(
                File::Spec->rel2abs(File::Spec->updir),
                'perl-from-github'
            );
        },
        configord  => 3,
    );
}

sub gitbare {
    return $opt->new(
        name       => 'gitbare',
        option     => '!',
        default    => 0,
        helptext   => "Clone as a bare repository",
        configtext => "Clone bare git repository?",
        configtype => 'prompt_yn',
        configalt  => sub { [qw/ y N /] },
        configdft  => sub {'n'},
    );
}



sub gitdfbranch {
    return $opt->new(
        name       => 'gitdfbranch',
        option     => '=s',
        default    => 'blead',
        helptext   => "The name of the gitbranch you smoke.",
        configtext => "Which branch should be smoked by default?",
        configtype => 'prompt',
        configalt  => sub { [] },
        configord  => 4,
    );
}

sub gitbranchfile {
    return $opt->new(
        name       => 'gitbranchfile',
        option     => '=s',
        default    => '',
        helptext   => "The name of the file where the gitbranch is stored.",
        configtext => "File name to put branch name for smoking in?",
        configtype => 'prompt_file',
        configalt  => sub { [] },
        configdft  => sub { my $self = shift; return $self->prefix . ".gitbranch" },
        configfnex => 1,
        configord  => 5,
    );
}

sub harness_destruct {
    return $opt->new(
        name => 'harness_destruct',
        option => 'harness-destruct=i',
        default => 2,
        helptext => "Sets \$ENV{PERL_DESTRUCT_LEVEL} for 'make test_harness'.",
    );
}

sub harness3opts {
    return $opt->new(
        name       => 'harness3opts',
        option     => '=s',
        default    => '',
        helptext   => "Extra options to pass to harness v3+.",
        configtext => "Extra options for Test::Harness 3
\tFor parallel testing use; 'j5'",
        configdft  => sub {''},
    );
}

sub harnessonly {
    return $opt->new(
        name       => 'harnessonly',
        option     => '!',
        default    => 0,
        helptext   => "Run test suite as 'make test_harness' (not make test).",
        configtext => "Use harness only (skip TEST)?",
        configtype => 'prompt_yn',
        configalt  => sub { [qw/ y N /] },
        configdft  => sub {'n'},
    );
}

sub hasharness3 {
    return $opt->new(
        name => 'hasharness3',
        option => '=i',
        default => 1,
        helptext => "Internal option for Test::Smoke::Smoker.",
    );
}

sub hdir { # hdir => ddir
    return $opt->new(
        name => 'hdir',
        option => '=s',
        helptext => "The local directory to hardlink from.",
    );
}

sub hostname {
    use System::Info;
    my $hostname = System::Info::si_uname('n');
    return $opt->new(
        name       => 'hostname',
        option     => '=s',
        deafult    => undef,
        helptext   => 'Use the hostname option to override System::Info->hostname',
        configtext => "Use this option to override the default hostname.
\tLeave empty for default ($hostname)",
    );
}

sub is56x {
    return $opt->new(
        name => 'is56x',
        option => '!',
        helptext => "Are we smoking perl maint-5.6?",
    );
}

sub is_vms {
    return $opt->new(
        name => 'is_vms',
        default => ($^O eq 'VMS'),
        helptext => "Internal, shows we're on VMS",
    );
}

sub is_win32 {
    return $opt->new(
        name => 'is_win32',
        default => ($^O eq 'MSWin32'),
        helptext => "Internal, shows we're on MSWin32",
    );
}

sub jsnfile {
    return $opt->new(
        name => 'jsnfile',
        option => '=s',
        default => 'mktest.jsn',
        helptext => 'Name of the file to store the JSON report in.',
    );
}

sub jsonreport {
    return $opt->new(
        name     => 'jsonreport',
        option   => '=s',
        default  => undef,
        helptext => "Name of json report file to re-post to the server"
                  . " (Takes precedence over '--adir' and '--sha')",
    );
}

sub killtime {
    return $opt->new(
        name => 'killtime',
        option => '=s',
        default => '',
        allow => [undef, '', qr/^\+?[0-9]{1,2}:[0-9]{2}$/],
        helptext => "The absolute or relative time the smoke may run.",
        configtext => <<"EOT",
Should this smoke be aborted on/after a specific time?
\tuse HH:MM to specify a point in time (24 hour notation)
\tuse +HH:MM to specify a duration
\tleave empty to finish the smoke without aborting
EOT
        configdft => sub { "" },
    );
}

sub lfile {
    return $opt->new(
        name => 'lfile',
        option => '=s',
        default => '',
        helptext => 'Name of the file to store the smoke log in.',
    );
}

sub locale {
    return $opt->new(
        name       => 'locale',
        option     => '=s',
        default    => '',
        allow      => [undef, '', qr{utf-?8$}i],
        helptext   => "Choose a locale to run the test suite under.",
        configtext => "What locale should be used for extra testing?
\t(Leave empty for none)",
    );
}

sub mail {
    return $opt->new(
        name       => 'mail',
        option     => '!',
        allow      => [ 0, 1 ],
        default    => 0,
        helptext   => "Send report via mail.",
        configtext => 'The existence of the mailing-list is not guarenteed',
        configtype => 'prompt_yn',
        configalt  => sub { [qw/ y N /] },
        configdft  => sub {'n'},
    );
}

sub mail_type {
    my $mail_type = $opt->new(
        name   => 'mail_type',
        option => 'mailer=s',
        allow  => [qw/sendmail mail mailx sendemail Mail::Sendmail MIME::Lite/],
        default  => 'Mail::Sendmail',
        helptext => "The type of mailsystem to use.",
        configalt  => _helper('get_avail_mailers'),
        configdft  => sub { (_helper('get_avail_mailers')->())[0] },
    );
}

sub mailbin {
    return $opt->new(
        name       => 'mailbin',
        option     => '=s',
        default    => 'mail',
        helptext   => "The name of the 'mail' program.",
        configtext => 'The fully qualified name of the executable.',
        configdft  => sub { (_helper(whereis => ['mail'])->())->[0] },
    );
}

sub mailxbin {
    return $opt->new(
        name       => 'mailxbin',
        option     => '=s',
        default    => 'mailx',
        helptext   => "The name of the 'mailx' program.",
        configtext => 'The fully qualified name of the executable.',
        configdft  => sub { (_helper(whereis => ['mailx'])->())->[0] },
    );
}

sub makeopt {
    require Config;
    return $opt->new(
        name       => 'makeopt',
        option     => '=s',
        default    => '',
        helptext   => "Extra option to pass to make.",
        configtext => "Specify extra arguments for '$Config::Config{make}'\n"
                    . "\t(for the 'build' and 'test_prep' steps)",
        configdft  => sub { '' },
    );
}

sub max_reports {
    return $opt->new(
        name => 'max_reports',
        option => 'max-reports|max=i',
        default => 10,
        helptext => "Maximum number of reports to pick from",
    );
}

sub mdir { # mdir => fdir => ddir
    return $opt->new(
        name => 'mdir',
        option => '=s',
        helptext => "The master directory of the Hardlink-Forest.",
    );
}

sub minus_des {
    return $opt->new(
        name     => 'des',
        option   => 'usedft',
        helptext => "Use all the default values.",
    );
}

sub mspass {
    return $opt->new(
        name       => 'mspass',
        option     => '=s',
        helptext   => 'Password for <msuser> for SMTP server.',
        configtext => "Type the password: 'noecho' but plain-text in config file!",
        configtype => 'prompt_noecho',
    );
}

sub msport {
    return $opt->new(
        name       => 'msport',
        option     => '=i',
        default    => 25,
        helptext   => 'Which port for SMTP server to send reports.',
        configtext => "Some SMTP servers use port 465 or 587",
    );
}

sub msuser {
    return $opt->new(
        name       => 'msuser',
        option     => '=s',
        default    => undef,
        allow      => [ undef, '', qr/\w+/ ],
        helptext   => 'Username for SMTP server.',
        configtext => "This is the username for logging into the SMTP server\n"
                    . "    leave empty if you don't have to login",
    );
}

sub mserver {
    return $opt->new(
        name       => 'mserver',
        option     => '=s',
        default    => 'localhost',
        helptext   => 'Which SMTP server to send reports.',
        configtext => "SMTP server to use for sending reports",
    );
}

sub opt_continue {
    return $opt->new(
        name => 'continue',
        option => '',
        default => 0,
        helptext => "Continue where last smoke left-off.",
    );
}

sub outfile {
    return $opt->new(
        name => 'outfile',
        option => '=s',
        default => 'mktest.out',
        helptext => 'Name of the file to store the raw smoke log in.',
    );
}

sub pass_option {
    return $opt->new(
        name => 'pass_option',
        option => 'pass-option|p=s@',
        default => [],
        allow => sub {
            my ($list) = @_;
            return unless ref($list) eq 'ARRAY';
            for my $to_pass (@$list) {
                return unless $to_pass =~ m{^ - [DUA] .+ $}x;
            }
            return 1;
        },
        helptext => 'Pass these options to Configure.',
    );
}

sub patchlevel {
    return $opt->new(
        name => 'patchlevel',
        option => '=s',
        helptext => "State the 'patchlevel' of the source-tree (for --nosync).",
    );
}

sub perl_version {
    return $opt->new(
        name   => 'perl_version',
        option => '=s',
        allow  => qr{^ (?:blead | 5 [.] (?: [2][68] | [3-9][02468] ) [.] x+ ) $}x,
        dft    => 'blead',
    );
}

sub perl5lib {
    return $opt->new(
        name       => 'perl5lib',
        option     => '=s',
        dft        => exists($ENV{PERL5LIB}) ? $ENV{PERL5LIB} : '',
        helptext   => "What value should be used for PERL5LIB in the jcl wrapper?\n",
        configtext => "\$PERL5LIB will be set to this value during the smoke\n"
                    . "\t(Make empty, with single space, to not set it.)",
    );
}

sub perl5opt {
    return $opt->new(
        name       => 'perl5opt',
        option     => '=s',
        dft        => exists($ENV{PERL5OPT}) ? $ENV{PERL5OPT} : '',
        helptext   => "What value should be used for PERL5OPT in the jcl wrapper?\n",
        configtext => "\$PERL5OPT will be set to this value during the smoke\n"
                    . "\t(Make empty, with single space, to not set it.)",
    );
}

sub perlio_only {
    return $opt->new(
        name       => 'perlio_only',
        option     => '!',
        default    => 0,
        helptext   => "Do not set the test suite environment to stdio.",
        configtext => "Run the test suite without \$ENV{PERLIO}=='stdio'?",
        configtype => 'prompt_yn',
        configalt  => sub { [qw/ N y /] },
        configdft  => sub {'n'},
    );
}

sub poster {
    return $opt->new(
        name       => 'poster',
        option     => '=s',
        allow      => [qw/HTTP::Tiny LWP::UserAgent curl/],
        default    => 'HTTP::Tiny',
        helptext   => "The type of HTTP post system to use.",
        configtext => "Which HTTP client do you want to use?",
        configalt  => _helper('get_avail_posters'),
        configdft  => sub { (_helper('get_avail_posters')->())[0] },
        configord  => 2,
    );
}

sub qfile {
    return $opt->new(
        name       => 'qfile',
        option     => '=s',
        allow      => [undef, '', qr{^[\w./:\\-]+$}],
        default    => undef,
        helptext   => 'The qfile keeps the queue of reports to resend.',
        configtext => "One can now queue reports if they couldn't be delevered.\n"
                    . "\tLeave empty for no queue.",
        configdft => sub {undef},
    );
}

sub report {
    my $default = @_ ? shift : 1;
    return $opt->new(
        name => 'report',
        option => '!',
        default => $default,
        helptext => "Create the report/json files.",
    );
}

sub rptfile {
    return $opt->new(
        name => 'rptfile',
        option => '=s',
        default => 'mktest.rpt',
        helptext => 'Name of the file to store the email report in.',
    );
}

sub rsyncbin {
    return $opt->new(
        name       => 'rsync',                                         #old name
        option     => '=s',
        default    => 'rsync',                                         # you might want a path there
        helptext   => "The name of the 'rsync' programe.",
        configtext => "Which 'rsync' binary do you want to use?",
        configtype => 'prompt_file',
        configdft  => sub { (_helper(whereis => ['rsync'])->())->[0] },
        configord  => 1,
    );
}

sub rsyncsource {
    return $opt->new(
        name       => 'source',
        option     => '=s',
        default    => 'rsync://dromedary.p5h.org:5872/perl-current/',
        helptext   => "The remote location of the rsync archive.",
        configtext => "Where would you like to rsync from?",
        configtype => 'prompt',
        configord  => 2,
    );
}

sub rsyncopts {
    return $opt->new(
        name       => 'opts',
        option     => '=s',
        default    => '-az --delete',
        helptext   => "Options to use for the 'rsync' program",
        configtext => "Which arguments should be used for rsync?",
        configtype => 'prompt',
        configord  => 3,
    );
}

sub send_log {
    my $allow = [qw/ never on_fail always /];
    return $opt->new(
        name       => 'send_log',
        option     => '=s',
        default    => 'on_fail',
        allow      => $allow,
        helptext   => "Send logfile to the CoreSmokeDB server.",
        configtext => "Do you want to send the logfile with the report?",
        configalt  => sub {$allow},
        configdft  => sub {'on_fail'},
        configord  => 4,
    );
}

sub send_out {
    my $allow = [qw/ never on_fail always /];
    return $opt->new(
        name       => 'send_out',
        option     => '=s',
        default    => 'never',
        allow      => $allow,
        helptext   => "Send out-file to the CoreSmokeDB server.",
        configtext => "Do you want to send the outfile with the report?",
        configalt  => sub {$allow},
        configdft  => sub {'never'},
        configord  => 5,
    );
}

sub sendemailbin {
    return $opt->new(
        name       => 'sendemailbin',
        option     => '=s',
        default    => 'sendemail',
        helptext   => "The name of the 'sendemail' program.",
        configtext => 'The fully qualified name of the executable.',
        configdft  => sub { (_helper(whereis => ['sendemail'])->())->[0] },
    );
}

sub sendmailbin {
    return $opt->new(
        name       => 'sendmailbin',
        option     => '=s',
        default    => 'sendmail',
        helptext   => "The name of the 'sendmail' program.",
        configtext => 'The fully qualified name of the executable.',
        configdft  => sub { (_helper(whereis => ['sendmail'])->())->[0] },
    );
}

sub sendreport {
    return $opt->new(
        name => 'sendreport',
        option => '!',
        default => 1,
        helptext => "Send the report mail/CoreSmokeDB.",
    );
}

sub showcfg {
    return $opt->new(
        name => 'showcfg',
        option => '!',
        default => 0,
        helptext => "Show a complete overview of all build configurations.",
    );
}

sub skip_tests {
    return $opt->new(
        name       => 'skip_tests',
        option     => '=s',
        helptext   => "Name of the file to store tests to skip.",
        configtext => "What file do you want to use to specify tests to skip.
\t(Make empty for none)",
        configtype => 'prompt_file',
        configfnex => 1,
        configdft  => sub {
            my $app = shift;
            $app->prefix . ".skiptests";
        },
    );
}

sub smartsmoke {
    return $opt->new(
        name       => 'smartsmoke',
        option     => '!',
        allow      => [ 0, 1 ],
        default    => 1,
        helptext   => "Do not smoke when the source-tree did not change.",
        configtext => "Skip smoke unless patchlevel changed?",
        configtype => 'prompt_yn',
        configalt  => sub { [qw/ Y n/] },
        configdft  => sub {'y'},
    );
}

sub smokedb_url {
    my $default = 'https://perl5.test-smoke.org/api/report';
    return $opt->new(
        name       => 'smokedb_url',
        option     => '=s',
        default    => $default,
        helptext   => "The URL for sending reports to CoreSmokeDB.",
        configtext => "Where do I send the reports?",
        configdft  => sub { $default },
        configord  => 1,
    );
}

sub sync {
    return $opt->new(
        name => 'sync',
        option => 'fetch!',
        default => 1,
        helptext => "Synchronize the source-tree before smoking.",
    );
}

sub sync_type {
    return $opt->new(
        name       => 'sync_type',
        option     => '=s',
        allow      => [qw/git rsync copy ftp snapshot/],
        default    => 'git',
        helptext   => 'The source tree sync method.',
        configtext => 'How would you like to sync the perl-source?',
        configtype => 'prompt',
        configalt  => _helper( get_avail_sync => [ ]),
    );
}

sub swbcc {
    return $opt->new(
        name => 'swbcc',
        option => '=s',
        default => '-b',
        helptext => 'The syntax of the commandline switch for BCC.',
    );
}

sub swcc {
    return $opt->new(
        name => 'swcc',
        option => '=s',
        default => '-c',
        helptext => 'The syntax of the commandline switch for CC.',
    );
}

sub testmake { # This was an Alan Burlison request.
    require Config;
    return $opt->new(
        name       => 'testmake',
        option     => '=s',
        default    => undef,
        helptext   => "A different make program for 'make _test'.",
        configtext => "Specify a different make binary for 'make _test'?",
        configdft  => sub {
            $Config::Config{make} ? $Config::Config{make} : 'make'
        },
    );
}

sub to {
    my $mailing_list = 'daily-build-reports@perl.org';
    return $opt->new(
        name       => 'to',
        option     => '=s',
        default    => $mailing_list,
        allow      => [qr/@/],
        helptext   => 'Where to send the reports to.',
        configtype => 'prompt',
        configtext => 'This is the email address used to send TO:',
        configdft  => sub {$mailing_list},
    );
}

sub ua_timeout {
    return $opt->new(
        name       => 'ua_timeout',
        option     => '=i',
        default    => 30,
        allow      => qr/^[1-9][0-9]{0,5}$/,
        helptext   => "The timeout to set the LWP::UserAgent.",
        configtext => "What should the timeout for the useragent be?",
        configdft  => sub {30},
        configord  => 3,
    );
}

sub un_file {
    return $opt->new(
        name       => 'un_file',
        option     => '=s',
        helptext   => "Name of the file with the 'user_note' text.",
        configtext => "In which file will you store your personal notes?
\t(Leave empty for none.)",
        configtype => 'prompt_file',
        configfnex => 1,
        configdft  => sub {
            my $app = shift;
            return $app->prefix . '.usernote';
        },
    );
}

sub un_position {
    return $opt->new(
        name       => 'un_position',
        option     => '=s',
        allow      => ['top', 'bottom'],
        default    => 'bottom',
        helptext   => "Position of the 'user_note' in the smoke report.",
        configtext => "Where do you want your personal notes in the report?",
        configalt  => sub { [qw/top bottom/] },
        configdft  => sub {'bottom'},
    );
}

sub user_note {
    return $opt->new(
        name => 'user_note',
        option => '=s',
        helptext => "Extra text to insert into the smoke report.",
    );
}

sub v {
    return $opt->new(
        name       => 'v',
        option     => ':1',
        default    => 1,
        allow      => [0, 1, 2],
        helptext   => "Log-level during smoke",
        configtext => "How verbose do you want the output?",
        configalt  => sub { [0, 1, 2] },
    );
}

sub vmsmake {
    return $opt->new(
        name => 'vmsmake',
        option => '=s',
        default => 'MMK',
        helptext => "The make program on VMS.",
    )
}

sub w32args {
    return $opt->new(
        name => 'w32args',
        option => '=s@',
        default => [],
        helptext => "Extra options to pass to W32Configure.",
    )
}

sub w32cc {
    return $opt->new(
        name => 'w32cc',
        option => '=s',
        helptext => "The compiler on MSWin32.",
    );
}

sub w32make {
    return $opt->new(
        name => 'w32make',
        option => '=s',
        default => 'gmake',
        helptext => "The make program on MSWin32.",
    );
}

sub _helper {
    my ($helper, $args) = @_;

    return sub {
        require Test::Smoke::Util::FindHelpers;
        my $run_helper = Test::Smoke::Util::FindHelpers->can($helper);
        my @values;
        if ($helper =~ m{(?:mailers)}) {
            my %helpers = $run_helper->(@$args);
            @values = sort keys %helpers;
        }
        else {
            @values = $run_helper->( @$args );
        }

        return [ @values ];
    }
}

1;

=head1 COPYRIGHT

(c) 2002-2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

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
