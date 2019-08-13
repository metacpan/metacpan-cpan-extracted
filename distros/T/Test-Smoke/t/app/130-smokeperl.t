#! perl -w
use strict;

BEGIN {
    *CORE::GLOBAL::localtime = sub { @_ ? CORE::localtime(shift) : CORE::localtime() };
}

use Test::More;
use Test::NoWarnings ();

use File::Path;
use File::Temp 'tempdir';
use File::Spec::Functions;
use Test::Smoke::App::SmokePerl;
use Test::Smoke::App::Options;
my $opt = 'Test::Smoke::App::Options';
$Test::Smoke::LogMixin::USE_TIMESTAMP = 0;

my $tmpdir = tempdir(CLEANUP => ($ENV{SMOKE_DEBUG} ? 0 : 1));
my $ddir = catdir($tmpdir, 'perl');
mkpath($ddir);
{
    fake_out($ddir);
    no warnings 'redefine';
    local *CORE::GLOBAL::localtime = sub {
        return (2, 11, 14, 15, 3, 115, 3, 104, 1);
    };
    local *Test::Smoke::App::SyncTree::run   = \&smarty_pants;
    local *Test::Smoke::App::RunSmoke::run   = \&smarty_pants;
    local *Test::Smoke::App::Reporter::run   = \&smarty_pants;
    local *Test::Smoke::App::SendReport::run = \&smarty_pants;
    local *Test::Smoke::App::Archiver::run   = \&smarty_pants;

    {
        open my $log, '>', \my $logfile;
        my $stdout = select $log;
        local @ARGV = (
            '--ddir'    => $ddir,
            '--verbose' => 1,
        );
        my $app = Test::Smoke::App::SmokePerl->new($opt->smokeperl_config());
        isa_ok($app, 'Test::Smoke::App::SmokePerl');

        my $outfile = catfile($ddir, 'mktest.out');
        $app->run();
        select $log;
        is($logfile, <<"        EOL", "basic run");
==> Starting synctree
calling ->run() from Test::Smoke::App::SyncTree
==> Starting runsmoke
calling ->run() from Test::Smoke::App::RunSmoke
Reading smokeresult from $outfile
Processing [-Duse64bitint]
Processing [-DDEBUGGING -Duse64bitint]
==> Starting reporter
calling ->run() from Test::Smoke::App::Reporter
==> Starting sendreport
calling ->run() from Test::Smoke::App::SendReport
==> Starting archiver
calling ->run() from Test::Smoke::App::Archiver
        EOL
    }
    {
        local @ARGV = (
            '--ddir'    => $ddir,
            '--verbose' => 1,
            '--nosync',
            '--noreport',
            '--nosendreport',
            '--noarchive',
            '--nosmartsmoke',
        );
        my $app = Test::Smoke::App::SmokePerl->new($opt->smokeperl_config());
        isa_ok($app, 'Test::Smoke::App::SmokePerl');

        open my $log, '>', \my $logfile;
        my $stdout = select $log;
        $app->run();
        select $log;
        is($logfile, <<'        EOL', "basic run");
==> Skipping synctree
==> Starting runsmoke
calling ->run() from Test::Smoke::App::RunSmoke
==> Skipping reporter
==> Skipping sendreport
==> Skipping archiver
        EOL
    }
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();

sub smarty_pants {
    my $self = shift;
    $self->log_warn("calling ->run() from %s", ref($self));
}

sub fake_out {
    my $outfile = catfile(shift, Test::Smoke::App::Options->outfile->default);
    open my $fh, '>', $outfile or die "Cannot create($outfile): $!";
    print $fh <<"    EOH";
Started smoke at 1370775768
Smoking patch 5f425cbef56bf693b214e78fe4ac4fbc3cba54d9 v5.19.0-450-g5f425cb
Smoking branch blead
Stopped smoke at 1370775768
Started smoke at 1370775768

Configuration: -Dusedevel -Duse64bitint
------------------------------------------------------------------------------

Compiler info: cc version Sun C 5.12 SunOS_i386 2011/11/16
TSTENV = stdio  u=4.55  s=2.31  cu=304.84  cs=32.93  scripts=2193  tests=680120

Inconsistent test results (between TEST and harness):
    ../t/cpan/Socket/t/getnameinfo.t........ ..................................... FAILED at test 10
    ../t/porting/pending-author.t........... ...................................... FAILED at test 1

TSTENV = perlio u=4.02  s=2.20  cu=277.19  cs=28.62  scripts=2194  tests=680289

Inconsistent test results (between TEST and harness):
    ../t/cpan/Socket/t/getnameinfo.t........ ..................................... FAILED at test 10
    ../t/porting/pending-author.t........... ...................................... FAILED at test 1

TSTENV = locale:en_US.UTF-8     u=4.02  s=2.32  cu=283.41  cs=29.00  scripts=2192  tests=680181

Inconsistent test results (between TEST and harness):
    ../t/cpan/Socket/t/getnameinfo.t........ ..................................... FAILED at test 10
    ../t/porting/pending-author.t........... ...................................... FAILED at test 1

Finished smoking 5f425cbef56bf693b214e78fe4ac4fbc3cba54d9 v5.19.0-450-g5f425cb blead
Stopped smoke at 1370777975
    EOH
    close $fh;
}
