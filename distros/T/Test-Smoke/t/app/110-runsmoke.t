#! perl -w
use strict;

BEGIN {
    *CORE::GLOBAL::localtime = sub { @_ ? CORE::localtime(shift) : CORE::localtime() };
}

use Test::More;
use Test::NoWarnings ();

use File::Spec::Functions;
use File::Path;
use File::Temp 'tempdir';
use Cwd 'abs_path';

BEGIN {
    $INC{'Test/Smoke/Smoker.pm'} = 'fake';
}

use Test::Smoke::App::RunSmoke;
use Test::Smoke::App::Options;
$Test::Smoke::LogMixin::USE_TIMESTAMP = 0;

my $win_error_setting = $^O eq 'MSWin32'
    ? "\012Changing ErrorMode settings to prevent popups"
    : '';

my $tmpdir = tempdir(CLEANUP => ($ENV{SMOKE_DEBUG} ? 0 : 1));
{ # Basic test, check we die() if the directory doesn't exist.

    my $ddir = catdir($tmpdir, 'will_not_exist_..._ever_I_hope');
    local @ARGV = ('--ddir', $ddir);
    my $app = Test::Smoke::App::RunSmoke->new(
        Test::Smoke::App::Options->runsmoke_config()
    );
    isa_ok($app, 'Test::Smoke::App::RunSmoke');

    eval { $app->run() };
    is(0+$!, 2, "->run() fails: $!");
}

my $ddir = catdir($tmpdir, 'perl');
mkpath($ddir, $ENV{TEST_VERBOSE});
{ # Basic test, override ->run() with something predictable
    local @ARGV = ('--ddir', $ddir, '--verbose', 1);
    my $app = Test::Smoke::App::RunSmoke->new(
        Test::Smoke::App::Options->runsmoke_config()
    );
    isa_ok($app, 'Test::Smoke::App::RunSmoke');

    no warnings 'redefine';
    local *CORE::GLOBAL::localtime = sub (;$) {
        return (2, 11, 14, 15, 3, 115, 3, 104, 1);
    };
    local *Test::Smoke::App::RunSmoke::run_smoke = sub {
        my $self = shift;
        $self->log_warn("%s::run_smoke...", ref $self);
    };

    my $cwd = Cwd::cwd;
    open my $fh, '>', \my $logfile;
    my $stdout = select $fh;
    $app->run();
    select $stdout;

    is($logfile, <<"    EOL", "logfile");
[$0] chdir($ddir)$win_error_setting
Test::Smoke::App::RunSmoke::run_smoke...
    EOL

    chdir($cwd);
}

########## Do stuff
{ # Test with overridden Test::Smoke::Smoker
    my $cdir = catdir(abs_path(), 't', 'ftppub', 'perl-current');
    local @ARGV = (
        '--ddir'      => $ddir,
        '--sync_type' => 'copy',
        '--cdir'      => $cdir,
        '--verbose'   => 0,
    );
    require Test::Smoke::App::SyncTree;
    my $sync = Test::Smoke::App::SyncTree->new(
        Test::Smoke::App::Options->synctree_config(),
    );
    $sync->run();

    local @ARGV = (
        '--ddir'      => $ddir,
        '--sync_type' => 'copy',
        '--cdir'      => $cdir,
        '--verbose'   => 1,
        # also test the new --pass_option switch
        '-p'          => '-Dusesuperthreads',
        '-p'          => '-Uusesuperfiles',
    );
    my $app = Test::Smoke::App::RunSmoke->new(
        Test::Smoke::App::Options->runsmoke_config()
    );
    isa_ok($app, 'Test::Smoke::App::RunSmoke');

    no warnings 'redefine', 'once';
    local *CORE::GLOBAL::localtime = sub (;$) {
        return (2, 11, 14, 15, 3, 115, 3, 104, 1);
    };
    local *Test::Smoke::Smoker::new = sub {
        my $class = shift;;
        return bless {}, $class;
    };
    local *Test::Smoke::Smoker::mark_in  = sub { };
    local *Test::Smoke::Smoker::mark_out = sub { };
    local *Test::Smoke::Smoker::make_distclean = sub { };
    local *Test::Smoke::Smoker::ttylog = sub { };
    local *Test::Smoke::Smoker::tty    = sub { };
    local *Test::Smoke::Smoker::log    = sub { };
    local *Test::Smoke::Smoker::smoke = sub {
        my $self = shift;
        my ($bldcfg) = @_;
        ok($bldcfg->has_arg(qw( -Dusesuperthreads -Uusesuperfiles )), "Found extra arguments");
    };

    # Replace this version of Test::Harness with a beta-version RT-118879
    my $thp = catfile(catdir($ddir, 'cpan', 'Test-Harness', 'lib', 'Test'), 'Harness.pm');
    my $th_version = '3.42_01';
    {
        open my $fh, '>', $thp;
        print $fh "package Test::Harness;\nour \$VERSION='$th_version';\n1\n";
        close $fh;
    }

    open my $fh, '>', \my $logfile;
    my $stdout = select $fh;
    eval { $app->run() };
    select $stdout;

    my $plh = catfile($ddir, 'patchlevel.h');

    is($logfile, <<"    EOL", "logfile after RunSmoke") and note($logfile);
[$0] chdir($ddir)$win_error_setting
qx[$^X -e "require q[$thp];print Test::Harness->VERSION" 2>&1]
Found: Test::Harness version $th_version.
Reading build configurations from internal content
Reading 'Policy.sh' from default content (v=1)
Locally applied patches from '$plh'
Patches: 'DEVEL19999'
Adding 'SMOKE37800ef622734ef3d18eddf53581505ff036f4b6' to the registered patches.
    EOL
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
