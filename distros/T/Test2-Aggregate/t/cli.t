use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Config;
use POSIX ();

plan skip_all => 'Helper scripts require Unix paths' if $^O eq 'MSWin32';

my $repo = path('.')->absolute;
my $tmp = Path::Tiny->tempdir;
my $suite = $tmp->child("suite with 'quote");
my $out = $tmp->child('output');
my $bin = $tmp->child('bin');
$_->mkpath for ($suite, $out, $bin);
my $pass = $suite->child('pass.t');
my $fail = $suite->child('fail.t');
$pass->spew_utf8("use Test::More; ok(1, 'passing'); done_testing;\n");
$fail->spew_utf8("use Test::More; ok(0, 'failing'); done_testing;\n");
$bin->child('prove')->spew_utf8("#!$^X\nuse App::Prove; my \$app = App::Prove->new; \$app->process_args(\@ARGV); exit(\$app->run ? 0 : 1);\n");
chmod 0755, $bin->child('prove');
local $ENV{PATH} = "$bin";
local $ENV{PERL5LIB} = join($Config{path_sep}, "$repo/lib", $ENV{PERL5LIB} || ());
local $ENV{PERL5OPT} = '';

my $counter = 0;
sub run_command {
    my ($cwd, @cmd) = @_;
    my $log = $tmp->child('log-' . ++$counter);
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        POSIX::setpgid(0, 0);
        chdir $cwd or die "chdir $cwd: $!";
        open STDOUT, '>', "$log" or die "open log: $!";
        open STDERR, '>&STDOUT' or die "redirect stderr: $!";
        exec @cmd or POSIX::_exit(127);
    }
    my $status;
    {
        local $SIG{ALRM} = sub { kill 9, -$pid; die "Command timed out: @cmd\n" };
        alarm 30;
        waitpid($pid, 0);
        $status = $?;
        alarm 0;
    }
    return ($status, $log->slurp_utf8);
}

sub helper {
    my ($script, @args) = @_;
    return run_command($repo, $^X, "$repo/$script", @args);
}

subtest 'agg paths and exec failures' => sub {
    my $list = $tmp->child('agg-input.lst');
    $list->spew_utf8($pass->relative($repo) . "\n");
    for my $mode ('absolute', 'root', 'lists', 'lists-absolute') {
        my @args = $mode eq 'absolute'
            ? ('--absolute', "" . $pass->relative($repo))
            : $mode eq 'lists' ? ('--lists', "$list")
            : $mode eq 'lists-absolute' ? ('--absolute', '--lists', "$list")
            : ('--root', "$suite", 'pass.t');
        my $base = $out->child("agg-$mode");
        my ($status, $log) = helper('agg', '--prove', '--out', "$base", @args);
        is($status, 0, "$mode run succeeds") or diag $log;
        ($status, $log) = run_command($tmp, $^X, "$base.t");
        is($status, 0, "$mode runner works from another directory") or diag $log;
    }
    my $stub = $tmp->child('harness-present/Test2');
    $stub->mkpath;
    $stub->child('Harness.pm')->spew_utf8("package Test2::Harness; 1;\n");
    local $ENV{PERL5OPT} = '-I' . $stub->parent;
    my ($status, $log) = helper('agg', '--out', $out->child('no-yath'), "$pass");
    isnt($status, 0, 'missing executable is fatal');
    like($log, qr/Cannot execute test harness/, 'reports exec failure');
};

my $have_bail = eval { require Test2::Plugin::BailOnFail; 1 };
subtest 'aggit discovery and ordering' => sub {
    plan skip_all => 'Test2::Plugin::BailOnFail unavailable' unless $have_bail;
    for my $mode ('reverse', 'shuffle', 'sort', 'root', 'absolute', 'lists', 'lists-default', 'lists-absolute') {
        my $base = $out->child("aggit-$mode");
        my @args = ("$fail", "$pass");
        if ($mode eq 'root') {
            @args = ('--root', "$suite", 'fail.t', 'pass.t');
        } elsif ($mode eq 'absolute') {
            @args = ('--absolute', map { "" . $_->relative($repo) } ($fail, $pass));
        } elsif ($mode eq 'lists') {
            $suite->child('tests.lst')->spew_utf8("fail.t\npass.t\n");
            @args = ('--root', "$suite", '--lists', 'tests.lst');
        } elsif ($mode eq 'lists-default' || $mode eq 'lists-absolute') {
            my $list = $tmp->child('input.lst');
            $list->spew_utf8(join("\n", map { $_->relative($repo) } ($fail, $pass)) . "\n");
            @args = ('--lists', "$list");
            unshift @args, '--absolute' if $mode eq 'lists-absolute';
        } else {
            unshift @args, "--$mode";
        }
        my ($status, $log) = helper('aggit', '--prove', '--out', "$base", @args);
        is($status, 0, "$mode iteration succeeds") or diag $log;
        my @kept = grep {length} split /\n/, path("$base.lst")->slurp_utf8;
        is(scalar @kept, 1, "$mode retains exactly one test");
        like($kept[0] || '', qr{/pass\.t$}, "$mode retains passing test");
        unlike(path("$base.t")->slurp_utf8, qr/(?:reverse|shuffle|sort) =>/,
            "$mode runner does not reorder the list");
        ($status, $log) = run_command($tmp, $^X, "$base.t");
        is($status, 0, "$mode runner works from another directory") or diag $log;
    }
    my $second = $suite->child('second.t');
    $second->spew_utf8($pass->slurp_utf8);
    my $base = $out->child('retained-order');
    my ($status, $log) = helper('aggit', '--prove', '--reverse', '--out', "$base",
        "$fail", "$pass", "$second");
    is($status, 0, 'multiple survivors succeed') or diag $log;
    unlike($log, qr/Running test/, 'discovery dry run prints no TAP');
    is_deeply([split /\n/, path("$base.lst")->slurp_utf8],
        [map { "" . $_->relative($out) } ($second, $pass)],
        'discovery order is retained after removal');

    # Runner in a different directory than the cwd the list is relative to.
    my $exclude = $tmp->child('exclude.lst');
    $exclude->spew_utf8("# comment\n./" . $fail->relative($repo) . "\n");
    $base = $out->child('exclude-list');
    ($status, $log) = helper('aggit', '--prove', '--exclude_list', "$exclude",
        '--out', "$base", map { "" . $_->relative($repo) } ($fail, $pass, $second));
    is($status, 0, 'exclude list run succeeds') or diag $log;
    like($log, qr/iter 1: 2 test files/, 'excluded test is not attempted');
    unlike($log, qr/\*\* Removing/, 'excluded test did not need removal');
    is_deeply([map { "" . path($out, $_)->realpath } split /\n/, path("$base.lst")->slurp_utf8],
        [map { "" . $_->realpath } ($pass, $second)],
        'exclude list is applied with a runner outside the cwd');
};

subtest 'aggit applies -I to a project-local test bundle' => sub {
    plan skip_all => 'Test2::Plugin::BailOnFail unavailable' unless $have_bail;
    my $proj = $tmp->child('project');
    $proj->child('t/lib')->mkpath;
    $proj->child('t/lib/LocalBundle.pm')->spew_utf8("package LocalBundle;\n1;\n");
    $proj->child('t/pass.t')->spew_utf8($pass->slurp_utf8);
    my $base = $out->child('local-bundle');
    my ($status, $log) = run_command($proj, $^X, "$repo/aggit", '--prove',
        '-I', 't/lib', '--test_bundle', 'Test::More,LocalBundle',
        '--out', "$base", 't/pass.t');
    is($status, 0, 'bundle found through -I during discovery and run') or diag $log;
    like(path("$base.lst")->slurp_utf8, qr{t/pass\.t}, 'test retained');
};

subtest 'fallback and infrastructure failures' => sub {
    plan skip_all => 'Test2::Plugin::BailOnFail unavailable' unless $have_bail;
    my $stub = $tmp->child('harness-stub/Test2');
    $stub->mkpath;
    local $ENV{PERL5OPT} = '-I' . $stub->parent;
    $stub->child('Harness.pm')->spew_utf8("die qq(Harness unavailable\\n);\n");
    my ($status, $log) = helper('aggit', '--out', $out->child('fallback'), "$pass");
    is($status, 0, 'automatic prove fallback succeeds without --et') or diag $log;

    $stub->child('Harness.pm')->spew_utf8("package Test2::Harness; 1;\n");
    for my $failure ('missing', 'startup') {
        if ($failure eq 'startup') {
            $bin->child('yath')->spew_utf8("#!$^X\nprint STDERR qq(Startup failed\\n); exit 2;\n");
            chmod 0755, $bin->child('yath');
        }
        my $base = $out->child("failure-$failure");
        ($status, $log) = helper('aggit', '--out', "$base", "$pass");
        isnt($status, 0, "$failure harness is fatal");
        unlike($log, qr/\*\* Removing|Passing tests:/, 'does not remove tests or claim success');
        like(path("$base.lst")->slurp_utf8, qr/pass\.t/, 'candidate list is preserved');
    }

    my $end = $suite->child('end.t');
    $end->spew_utf8("use Test::More; ok(1); done_testing; END { die qq(END failure\\n) }\n");
    ($status, $log) = helper('aggit', '--prove', '--out', $out->child('end'), "$end");
    isnt($status, 0, 'post-suite failure is fatal');
    like($log, qr/without an identifiable active test/, 'reports unattributable failure');
    unlike($log, qr/\*\* Removing/, 'does not blame completed test');
};

subtest 'missing BailOnFail is explicit' => sub {
    my $stub = $tmp->child('no-bail/Test2/Plugin');
    $stub->mkpath;
    $stub->child('BailOnFail.pm')->spew_utf8("die qq(BailOnFail unavailable\\n);\n");
    local $ENV{PERL5OPT} = '-I' . $stub->parent->parent;
    my ($status, $log) = helper('aggit', '--prove', '--out', $out->child('no-bail'), "$pass");
    isnt($status, 0, 'missing plugin fails');
    like($log, qr/aggit requires Test2::Plugin::BailOnFail/, 'explains required dependency');
    ok(! $out->child('no-bail.lst')->exists, 'does not write a result list');
    ($status, $log) = run_command($repo, $^X, '-MTest2::Aggregate', '-e',
        'Test2::Aggregate::run_tests(bail_on_fail => 1)');
    isnt($status, 0, 'module also fails when requested plugin is unavailable');
    like($log, qr/BailOnFail unavailable/, 'module exposes load failure');
};

done_testing;
