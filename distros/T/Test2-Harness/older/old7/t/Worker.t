# HARNESS-NO-PRELOAD

# Fork handler for later, we need to do this now, before stuff is loaded.
our $FORK;
BEGIN {
    *CORE::GLOBAL::fork = sub() {
        return $FORK->() if $FORK;
        CORE::fork();
    };
}

use Test2::Bundle::Extended -target => 'Test2::Harness::Run::Worker';

use ok $CLASS;

use Test2::Harness::Run;
use Test2::Harness::Run::Job;
use Test2::Harness::Worker::TestFile;
use Test2::Util qw/clone_io IS_WIN32/;
use File::Temp qw/tempdir/;
use IPC::Open3 qw/open3/;
use Time::HiRes qw/sleep/;
use List::Util qw/first/;

subtest construction => sub {
    like(
        dies { $CLASS->new() },
        qr/The 'run' attribute is required/,
        "Need 'run'"
    );

    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);

    my $one = $CLASS->new(run => Test2::Harness::Run->new(dir => $dir, id => 'test1'));
    isa_ok($one, $CLASS);

    $one->run->save_config;
    my $two = $CLASS->new(run_dir => $dir);
    isa_ok($two, $CLASS);
    ok($two->run, "Loaded run");
    is($two->run->id, 'test1', "Loaded correct run");
};

subtest active => sub {
    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
    my $one = $CLASS->new(run => Test2::Harness::Run->new(dir => $dir, id => 'test1'));

    ok(!$one->active, "Not active");
    $one->{_active} = 1;
    ok($one->active, "Active");
    $one->{_active} = 0;
    ok(!$one->active, "Not active");

    my $wh;
    my $pid = open3($wh, \*STDERR, \*STDERR, $^X);
    $one->{proc} = Test2::Harness::Util::Proc->new(pid => $pid);
    ok($one->active, "active due to running process");

    my $has_exit = 0;
    {
        close($wh);    # Should terminate child process
        local $SIG{ALRM} = sub { die "timeout waiting for process to end" };
        alarm 10;
        while ($one->active) {
            $has_exit++ if defined $one->proc->exit;
            sleep 0.2;
        }
        alarm 0;
    }

    ok(!$one->active, "pid is not active anymore");
    is($has_exit, 1, "Extra TRUE 'active' response after pid reaped");

    ok(defined $one->proc->exit, "Got an exit value");
    is($one->proc->exit, 0, "Exit value 0");

    # Now again, but with failure
    $one = $CLASS->new(run => Test2::Harness::Run->new(dir => $dir, id => 'test1'));
    $pid = open3($wh, \*STDERR, \*STDERR, $^X, '-e', 'exit 42');
    $one->{proc} = Test2::Harness::Util::Proc->new(pid => $pid);
    ok($one->active, "active due to running proc");

    {
        #print $wh "exit 42;";
        close($wh);    # Should terminate child process
        local $SIG{ALRM} = sub { die "timeout waiting for process to end" };
        alarm 10;
        while (1) {
            eval { $one->active; 1 } and do {
                sleep 0.2;
                next;
            };
            like(
                $@,
                qr/Worker process\($pid\) failure \(Exit Code: 42\)/,
                "Got exception in worker process"
            );
            last;
        }
        alarm 0;
    }

    ok(defined $one->proc->exit, "Got an exit value");
    is($one->proc->exit, 42, "Exit value 42");
    close($wh);

    # Now again, but with another reaper
    $one = $CLASS->new(run => Test2::Harness::Run->new(dir => $dir, id => 'test1'));
    $pid = open3($wh, \*STDERR, \*STDERR, $^X);
    $one->{proc} = Test2::Harness::Util::Proc->new(pid => $pid);
    ok($one->active, "active due to running process");

    {
        local $SIG{ALRM} = sub { die "timeout waiting for process to end" };
        alarm 10;
        close($wh);    # Should terminate child process
        waitpid($pid, 0);
        alarm 0;
    }

    like(
        dies { $one->active },
        qr/process .* reap/i,
        "Noticed that something else reaped the process"
    );
};

subtest find_worker_script => sub {
    my $path = first { -d $_ && -f "$_/yath" && -f "$_/yath-worker" } 'scripts', '../scripts';
    skip_all "Could not find path to scripts" unless $path && -d $path;

    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
    my $one = $CLASS->new(run => Test2::Harness::Run->new(dir => $dir, id => 'test1'));

    local $0 = "$path/yath";
    is($one->find_worker_script, "$path/yath-worker", "Found worker by altering \$0");

    $0 = "";
    local $ENV{PATH} = $path;
    is($one->find_worker_script, "$path/yath-worker", "Found worker in path");

    $ENV{PATH} = "";
    like(
        dies { $one->find_worker_script },
        qr/Could not find 'yath-worker' in execution path/,
        "Could not find worker"
    );

    local $ENV{T2_HARNESS_WORKER_SCRIPT} = "Fake-Worker";
    like(
        dies { $one->find_worker_script },
        qr/Could not find 'Fake-Worker' in execution path/,
        "Can override worker script name with env var"
    );
};

subtest find_worker_inc => sub {
    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
    my $one = $CLASS->new(run => Test2::Harness::Run->new(dir => $dir, id => 'test1'));

    ok(my $path = $one->find_worker_inc, "got a path") or return;
    ok(-d $path,                           "Path is a directory");
    ok(-e "$path/Test2/Harness/Run/Worker.pm", "Found Worker.pm inside it");
};

subtest spawn => sub {
    my $self = shift;

    my $args;
    my $mock = mock 'Test2::Harness::Run::Worker' => (
        override => [
            open3 => sub { $args = [@_]; return 'fake-pid'; },
            find_worker_script => sub { 'yath-worker' },
            find_worker_inc    => sub { 'worker_inc' },
        ],
    );

    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
    my $one = $CLASS->new(run => Test2::Harness::Run->new(dir => $dir, id => 'test1'));

    local $^X = '!PERL!';
    $one->spawn;
    is($one->proc->pid, 'fake-pid', "set pid");
    is(
        $args,
        [
            undef,
            '>&1',
            '>&2',
            '!PERL!',
            '-Iworker_inc',
            'yath-worker',
            $CLASS,
            run_dir => $dir,
        ],
        "Correct args to IPC::Open3"
    );

    ok(-e "$dir/config.json", "wrote config");
};

subtest start => sub {
    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
    my $one = $CLASS->new(run => Test2::Harness::Run->new(dir => $dir, id => 'test1'));

    my $cb = sub { die "not yet" };
    my $mock = mock 'Test2::Harness::Run::Worker' => (
        override => [
            _start => sub { return $cb->(@_) },
        ],
    );

    $one->{_active} = 1;
    like(
        dies { $one->start },
        qr/^Worker is already active/,
        "Already active"
    );

    my $cur = File::Spec->rel2abs(File::Spec->curdir());
    $one->{_active} = 0;
    $cb = sub {
        is(File::Spec->rel2abs(File::Spec->curdir()), $cur, "Did not change dirs");
        is($one->{_active},                           1,    "active now");
        return "foo.t";
    };
    is(File::Spec->rel2abs(File::Spec->curdir()), $cur,    "Back to original dir");
    is($one->start(),                             'foo.t', "Got file to run");
    is($one->{_active},                           1,       "active now");

    $one->{_active}    = 0;
    $one->run->{chdir} = File::Spec->tmpdir;
    $cb                = sub {
        is(File::Spec->rel2abs(File::Spec->curdir()), File::Spec->tmpdir, "Did change dirs");
        is($one->{_active}, 1, "active now");
        return;
    };
    is(File::Spec->rel2abs(File::Spec->curdir()), $cur,  "Back to original dir");
    is($one->start(),                             undef, "No file to run");
    is($one->{_active},                           0,     "not active now");

    $one->{_active}    = 0;
    $one->run->{chdir} = File::Spec->tmpdir;
    $cb                = sub {
        is(File::Spec->rel2abs(File::Spec->curdir()), File::Spec->tmpdir, "Did change dirs");
        is($one->{_active}, 1, "active now");
        die "Ooops";
    };
    is(File::Spec->rel2abs(File::Spec->curdir()), $cur, "Back to original dir");
    like(
        dies { $one->start() },
        qr/Ooops/,
        "Exception test"
    );
    is($one->{_active}, 0, "not active now");
};

subtest run_open3 => sub {
    my $open3_args;
    my $open3_env;
    my $control = mock $CLASS => (
        override => [
            open3 => sub {
                $open3_args = [@_];
                $open3_env  = {%ENV};
                return 999_999_999;
            }
        ],
    );

    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
    my $run = Test2::Harness::Run->new(dir => $dir, id => 'run1');
    my $one = $CLASS->new(run => $run);

    my $job_id  = 1;
    my $job_dir = $run->path($job_id);
    mkdir($job_dir) or die "Could not create directory '$job_dir': $!";

    my $job = Test2::Harness::Run::Job->new(
        dir      => $job_dir,
        id       => $job_id,
        env_vars => {this_is_only_a_test => 'maybe?'},
        # Inception!
        test_file => __FILE__,
        test      => mock {} => (add => [switches => sub { '-w' }]),
    );

    $run->add_job($job);
    $job->set_start_stamp(time);

    is($one->run_open3($job), 999_999_999, "Got pid");
    is(
        $open3_args,
        array {
            item undef;
            item match qr/^>&(\d+)$/;
            # Make sure it is different from the last one using $1
            item check_set(mismatch qr/^>&$1$/, match qr/^>&\d+$/);
            item $^X;
            item '-w';
            item "-MTest2::Formatter::Stream=" . $job->events_file->name;
            item __FILE__;
            end;
        },
        "Ran expected open3 command"
    );
    like($open3_env, hash { field this_is_only_a_test => 'maybe?'; etc }, "Set the env for open3");
    like(\%ENV,      hash { field this_is_only_a_test => DNE();    etc }, "restored env hash");

    $run->{event_stream} = 0;
    is($one->run_open3($job), 999_999_999, "Got pid");
    is(
        $open3_args,
        array {
            item undef;
            item match qr/^>&\d+$/;
            # Make sure it is different from the last one using $1
            item check_set(mismatch qr/^>&$1$/, match qr/^>&\d+$/);
            item $^X;
            item '-w';
            item __FILE__;
            end;
        },
        "Ran expected open3 command"
    );
    like($open3_env, hash { field this_is_only_a_test => 'maybe?'; etc }, "Set the env for open3");
    like(\%ENV,      hash { field this_is_only_a_test => DNE();    etc }, "restored env hash");

    # no switches
    $job->{test} = mock {} => (add => [switches => sub { }]);
    $run->{event_stream} = 0;
    is($one->run_open3($job), 999_999_999, "Got pid");
    is(
        $open3_args,
        array {
            item undef;
            item match qr/^>&(\d+)$/;
            # Make sure it is different from the last one using $1
            item check_set(mismatch qr/^>&$1$/, match qr/^>&\d+$/);
            item $^X;
            item __FILE__;
            end;
        },
        "Ran expected open3 command"
    );
    like($open3_env, hash { field this_is_only_a_test => 'maybe?'; etc }, "Set the env for open3");
    like(\%ENV,      hash { field this_is_only_a_test => DNE();    etc }, "restored env hash");
};

subtest preload => sub {
    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
    my $run = Test2::Harness::Run->new(dir => $dir, id => 'run1');
    my $one = $CLASS->new(run => $run);

    my $preload_list = 0;
    my $control = mock $CLASS => (
        override => [preload_list => sub { $preload_list++ }],
    );

    local @INC = ('t/lib', @INC);
    local %INC = %INC;
    delete $INC{'Test2/Formatter/Stream.pm'};
    delete $INC{'FakeModule.pm'};

    {
        local %INC = %INC;
        $run->{event_stream} = 0;
        $one->preload;

        like(
            \%INC,
            {
                'Test2/Formatter/Stream.pm' => DNE(),
                'FakeModule.pm'             => DNE(),
            },
            "Nothing to preload"
        );

        ok(!$preload_list, "did not build preload list");
    }

    {
        local %INC = %INC;
        $run->{preload}      = ['FakeModule'];
        $run->{event_stream} = 0;
        $one->preload;

        like(
            \%INC,
            {
                'Test2/Formatter/Stream.pm' => DNE(),
                'FakeModule.pm'             => T(),
            },
            "Preloaded only the FakeModule"
        );

        ok($preload_list, "did not build preload list");
        $preload_list = 0;
    }

    {
        local %INC = %INC;
        $run->{preload}      = ['FakeModule'];
        $run->{event_stream} = 1;
        $one->preload;

        like(
            \%INC,
            {
                'Test2/Formatter/Stream.pm' => T(),
                'FakeModule.pm'             => T(),
            },
            "Loaded stream formatter and FakeModule"
        );

        ok($preload_list, "did not build preload list");
        $preload_list = 0;
    }
};

subtest preload_and_reset => sub {
    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
    my $run = Test2::Harness::Run->new(dir => $dir, id => 'run1');
    my $one = $CLASS->new(run => $run);

    local %INC = (
        'FakeModule/A.pm' => __FILE__,
        'FakeModule/B.pm' => __FILE__,
        'FakeModule/C.pm' => __FILE__,
    );

    no warnings 'once';
    my $fha = *FakeModule::A::DATA;
    my $fhb = *FakeModule::B::DATA;
    open($fha, '<', __FILE__) or die "Could not open file: $!";
    open($fhb, '<', __FILE__) or die "Could not open file: $!";
    seek($fha, 10, 0);
    seek($fhb, 20, 0);

    my @list = $one->preload_list;

    is(
        \@list,
        bag {
            item ['FakeModule::A', __FILE__, 10];
            item ['FakeModule::B', __FILE__, 20];
            end;
        },
        "Found both handles, skipped no-handle module"
    );

    seek($fha, 30, 0);
    seek($fhb, 30, 0);

    $one->_reset_DATA(__FILE__);

    # re-retrieve handles
    $fha = *FakeModule::A::DATA;
    $fhb = *FakeModule::B::DATA;

    is(tell($fha), 10, "reset first handle");
    is(tell($fhb), 20, "reset second handle");

    my @lines = <main::DATA>;
    like(
        \@lines,
        bag { item "DO NOT REMOVE THIS LINE\n" },
        "Reset 'main' handle"
    );
};

subtest run_preloaded => sub {
    no warnings 'once';
    no warnings 'redefine';
    local $0 = 'fake';
    is($0, 'fake', 'set $0 to a fake value for now');

    local @ARGV = (1, 2, 3);
    "foo" =~ m/(((((((((foo)))))))))/;    # Set $1
    is($1, "foo", "set \$1");
    is($9, "foo", "set \$9");

    my $reset = 0;
    my $c = mock $CLASS => (override => [_reset_DATA => sub { $reset++ }]);

    my $init = 0;
    local *FindBin::init = sub { $init++ };

    my $getopt = 0;
    local *Getopt::Long::ConfigDefaults = sub { $getopt++ };

    my $t2_reset = 0;
    local $INC{'Test2/API.pm'} = 1;
    local *Test2::API::test2_reset_io = sub { $t2_reset++ };

    my $tb = 0;
    local $Test::Builder::Test;
    local $INC{'Test/Builder.pm'} = 1;
    local *Test::Builder::new = sub { $tb++ };

    my %imports;
    local @INC = ('t/lib', @INC);
    local %INC = %INC;
    delete $INC{'Test2/Formatter/Stream.pm'};
    local *Test2::Formatter::Stream::import = sub { $imports{stream}   = [@_] };

    my $stdout = clone_io(\*STDOUT);
    my $stderr = clone_io(\*STDERR);
    my $ok     = eval {
        my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
        my $run = Test2::Harness::Run->new(dir => $dir, id => 'run1');
        my $one = $CLASS->new(run => $run);

        my $job_id  = 1;
        my $job_dir = $run->path($job_id);
        mkdir($job_dir) or die "Could not create directory '$job_dir': $!";

        my $job = Test2::Harness::Run::Job->new(
            dir      => $job_dir,
            id       => $job_id,
            env_vars => {this_is_only_a_test => 'maybe?'},
            # Inception!
            test_file => __FILE__,
            test      => mock {} => (add => [switches => sub { '-w' }]),
        );

        $run->{event_stream}  = 0;
        is($one->run_preloaded($job), __FILE__, "returned filename");

        # We redirected STDOUT
        print "not ok 0 - You should not see this!\n";
        print STDERR "You should not see this!\n";

        is($0, __FILE__, 'set $0 back to the file');
        is(\@ARGV, [], 'empty @ARGV');
        ok($reset,    "reset data handles");
        ok($init,     "reset FindBin");
        ok($getopt,   "reset Getopt::Long");
        ok($t2_reset, "reset Test2 outputs");
        ok($tb,       "reset Test::Builder");

        $run->{event_stream}  = 1;
        is($one->run_preloaded($job), __FILE__, "returned filename");
        is(
            $imports{stream},
            ['Test2::Formatter::Stream', $job->events_file->name],
            "Imported Test2::Formatter::Stream"
        );

        1;
    };
    my $err = $@;
    close(STDERR);
    open(STDERR, '>&', $stderr) or do { print $stderr "Could not restore STDERR, this is bad!: $!"; die "oops" };
    close(STDOUT);
    open(STDOUT, '>&', $stdout) or die "Could not restore STDOUT: $!";
    die $err unless $ok;
};

subtest wait => sub {
    my $run = mock {job_count => 3};
    my $one = $CLASS->new(run => $run);

    $one->{_jobs} = [
        mock({complete => 0, id => 1}),
        mock({complete => 0, id => 2}),
        mock({complete => 0, id => 3}),
    ];

    my $start = time;
    local $SIG{ALRM} = sub { $one->{_jobs}->[1]->{complete} = 1 };
    alarm 4;
    $one->_wait;
    alarm 0;
    ok(time - $start >= 3, "_wait blocked until a process finished");
    like(
        $one->{_jobs},
        array {
            item {id => 1};
            item {id => 3};
            end;
        },
        "Item 2 was removed"
    );

    delete $one->{_jobs};
};

subtest start => sub {
    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);
    my $run = Test2::Harness::Run->new(dir => $dir, id => 'run1', libs => ['foo']);
    my $one = $CLASS->new(run => $run);

    local @INC = ();

    my $c1 = mock 'Test2::Harness::Run' => (
        override => [
            find_tests => sub {
                Test2::Harness::Worker::TestFile->new(filename => 't/simple.t'),
                Test2::Harness::Worker::TestFile->new(filename => 't/simple.t'),
                Test2::Harness::Worker::TestFile->new(filename => 't/simple.t'),
                Test2::Harness::Worker::TestFile->new(filename => 't/simple.t'),
            },
        ],
    );

    my @seen;
    my $wait = 0;
    my $preload = 0;
    my $c2 = mock $CLASS => (
        override => [
            _finish => sub { },
            preload => sub { $preload++ },
            _wait   => sub { $wait++ },
            _start_job => sub {
                $one->{_jobs}->[-1]->{complete} = 1 if @{$one->{_jobs}};
                push @seen => mock {id => $_[2], complete => 0 };
                return $seen[-1];
            },
        ]
    );

    $one->start;

    is(@seen, 4, "saw 4 jobs");
    like($one->{_jobs}, [{id => 1}, {id => 2}, {id => 3}, {id => 4}], "Jobs were queued");
    ok(!$preload, "did not preload");
    is(\@INC, ['foo'], "set \@INC");
    is($wait, 4, "waited before each job");

    delete $one->{_jobs};

    @INC = ();
    @seen = ();
    $wait = 0;
    $run->{preload} = ['Test2::V0'];
    $one->start;

    is(@seen, 4, "saw 4 jobs");
    like($one->{_jobs}, [{id => 1}, {id => 2}, {id => 3}, {id => 4}], "Jobs were queued");
    ok($preload, "did not preload");
    is(\@INC, ['foo'], "set \@INC");
    is($wait, 4, "waited before each job");

    delete $one->{_jobs};

    $c2->override('_start_job' => sub { (undef, 'foo.t') });
    is($one->start, 'foo.t', "Propogated filename for return");
    delete $one->{_jobs};
};

subtest _start_job => sub {
    my $used;
    # No need for a real process to spawn, just let the parent continue
    my $fork_pid;
    local $FORK = sub() { $used = 'fork'; $fork_pid };
    my $c = mock $CLASS => (
        override => [run_open3 => sub { $used = 'open3'; 999999992 }]
    );

    my $dir = tempdir("T2-Harness-XXXXXXXX", CLEANUP => 1, TMPDIR => 1);

    subtest open3 => sub {
        my $run = Test2::Harness::Run->new(dir => $dir, id => 'run1');
        my $one = $CLASS->new(run => $run);

        my ($job, $file) = $one->_start_job(
            Test2::Harness::Worker::TestFile->new(filename => 't/simple.t'),
            42,
        );

        is($used, 'open3', "used open3");

        ok($job, "got a job") or return;
        ok(!$file, "Did not get a file") or return;

        ok(-d $run->path(42), "Created dir for job");

        is((grep { $_->id == 42 && $_->test_file eq 't/simple.t' } @{$run->jobs}), 1, "Job was added once");

        like(
            $job,
            object {
                call dir         => $run->path(42);
                call id          => 42;
                call test        => object { call filename => 't/simple.t' };
                call env_vars    => {%{$run->env_vars}};
                call start_stamp => D();
                call proc        => object { call pid => 999999992 };
            },
            "Constructed job"
        );
    };

    subtest fork_parent => sub {
        $fork_pid = 99999991;
        my $run = Test2::Harness::Run->new(dir => $dir, id => 'run1', preload => ['Scalar::Util']);
        my $one = $CLASS->new(run => $run);

        my ($job, $file) = $one->_start_job(
            Test2::Harness::Worker::TestFile->new(filename => 't/simple.t'),
            43,
        );

        is($used, 'fork', "used fork");

        ok($job, "got a job") or return;
        ok(!$file, "Did not get a file") or return;

        ok(-d $run->path(43), "Created dir for job");

        is((grep { $_->id == 43 && $_->test_file eq 't/simple.t' } @{$run->jobs}), 1, "Job was added once");

        like(
            $job,
            object {
                call dir         => $run->path(43);
                call id          => 43;
                call test        => object { call filename => 't/simple.t' };
                call env_vars    => {%{$run->env_vars}};
                call start_stamp => D();
                call proc        => object { call pid => $fork_pid };
            },
            "Constructed job"
        );
    };

    subtest fork_child => sub {
        $fork_pid = 0;
        my $run = Test2::Harness::Run->new(dir => $dir, id => 'run1', preload => ['Scalar::Util']);
        my $one = $CLASS->new(run => $run);

        my ($job, $file) = $one->_start_job(
            Test2::Harness::Worker::TestFile->new(filename => 't/simple.t'),
            44,
        );

        is($used, 'fork', "used fork");

        ok($job, "got a job") or return;
        is($file, "t/simple.t", "got file");

        ok(-d $run->path(44), "Created dir for job");

        is((grep { $_->id == 44 && $_->test_file eq 't/simple.t' } @{$run->jobs}), 1, "Job was added once");

        like(
            $job,
            object {
                call dir         => $run->path(44);
                call id          => 44;
                call test        => object { call filename => 't/simple.t' };
                call env_vars    => {%{$run->env_vars}};
                call start_stamp => D();
                call proc        => undef;
            },
            "Constructed job"
        );
    };

};

done_testing;

__DATA__

DO NOT REMOVE THIS LINE
