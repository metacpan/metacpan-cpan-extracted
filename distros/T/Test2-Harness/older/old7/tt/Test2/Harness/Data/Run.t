use Test2::Bundle::Extended -target => 'Test2::Harness::Run';

use File::Temp qw/tempdir tempfile/;

use ok $CLASS;

subtest construction => sub {
    like(dies { $CLASS->new }, qr/^One of 'dir', 'data', 'file' or 'path' is required/, "Must provide data somehow");
    like(dies { $CLASS->new(data => {}) }, qr/The 'id' attribute is required/, "Must provide data somehow");

    ok($CLASS->new(data => {}, id => 1), "Construction works");
    ok($CLASS->new(data => {id => 1}), "id can come from data");

    my $one = $CLASS->new(data => {}, id => 1);

    local $ENV{PERL_USE_UNSAFE_INC} = 1;
    like(
        $one,
        {
            chdir          => undef,
            search         => ['t'],
            preload        => undef,
            switches       => [],
            libs           => [],
            lib            => 0,
            blib           => 0,
            output_merging => 0,
            job_count      => 1,

            event_stream => 1,

            env_vars => {
                PERL_USE_UNSAFE_INC => 1,
                T2_HARNESS_RUN_ID   => 1,
                T2_HARNESS_JOBS     => 1,
                HARNESS_JOBS        => 1,
            },

        },
        "defaults",
    );
};

subtest path => sub {
    my $one = $CLASS->new(dir => '/fake/dir/for/test', id => 1);
    is($one->path, '/fake/dir/for/test', "no args gives root dir");
    is($one->path('a'), File::Spec->catfile('/fake/dir/for/test', 'a'), "Found file 'a'");
    is($one->path('a', 'b'), File::Spec->catfile('/fake/dir/for/test', 'a', 'b'), "Found file 'a/b'");

    my $two = $CLASS->new(data => {}, id => 1);
    like(dies { $two->path }, qr/'path' only works when using a directory/, "Cannot use path with non-dir");
};

subtest data => sub {
    my $make_data = sub {
        my $env = {
            PERL_USE_UNSAFE_INC => 1,
            T2_HARNESS_RUN_ID   => 111,
            T2_HARNESS_JOBS     => 1,
            HARNESS_JOBS        => 1,
        };

        return {
            id             => 111,
            job_count      => 1,
            switches       => [],
            libs           => [],
            lib            => 0,
            blib           => 0,
            preload        => undef,
            output_merging => 0,
            event_stream   => 1,
            chdir          => undef,
            search         => ['t'],
            unsafe_inc     => 1,
            env_vars       => $env,

            jobs => [
                {
                    id        => 123,
                    test_file => 'foo.t',
                    events    => [
                        {facets => {assert => {pass  => 1,   details  => 'test 1'}}, __FROM__ => 'fake'},
                        {facets => {assert => {pass  => 1,   details  => 'test 2'}}, __FROM__ => 'fake'},
                        {facets => {assert => {pass  => 1,   details  => 'test 3'}}, __FROM__ => 'fake'},
                        {facets => {plan   => {count => 3}}, __FROM__ => 'fake'},
                    ],
                    pid   => $$,
                    exit  => 127,
                    muxed => [
                        {stamp => 12345, fileno => 1, buffer => "stdout line 1\n"},
                        {stamp => 12345, fileno => 1, buffer => "stderr line 1\n"},
                        {stamp => 12345, fileno => 1, buffer => "stdout line 2\n"},
                        {stamp => 12345, fileno => 1, buffer => "stderr line 2\n"},
                        {stamp => 12345, fileno => 1, buffer => "stdout line 3\n"},
                        {stamp => 12345, fileno => 1, buffer => "stderr line 3\n"},
                    ],
                    stderr => [
                        "stderr line 1\n",
                        "stderr line 2\n",
                        "stderr line 3\n",
                    ],
                    stdout => [
                        "stdout line 1\n",
                        "stdout line 2\n",
                        "stdout line 3\n",
                    ],

                    start_stamp => 12345,
                    stop_stamp  => 12346,

                    env_vars => $env,
                },
                {id => 124, test_file => 'bar.t', pid => $$, start_stamp => 12345, stop_stamp => 12346, exit => 0, muxed => [], stderr => [], stdout => [], events => [], env_vars => $env},
                {id => 125, test_file => 'baz.t', pid => $$, start_stamp => 12345, stop_stamp => 12346, exit => 0, muxed => [], stderr => [], stdout => [], events => [], env_vars => $env},
            ],
        };
    };

    my $data = $make_data->();

    my $one = $CLASS->new(data => $data);

    subtest jobs => sub {
        my $job = $one->jobs->[0];

        is($job->pid,         $$,      "got pid");
        is($job->start_stamp, 12345,   "got start_stamp");
        is($job->stop_stamp,  12346,   "got stop_stamp");
        is($job->exit,        127,     "got exit");
        is($job->id,          123,     "got id");
        is($job->test_file,   'foo.t', "got test file");

        like(
            [$job->events],
            array {
                event '+Test2::Harness::Event' => sub {
                    call facet_data => {assert => {pass => 1, details => 'test 1'}};
                };
                event '+Test2::Harness::Event' => sub {
                    call facet_data => {assert => {pass => 1, details => 'test 2'}};
                };
                event '+Test2::Harness::Event' => sub {
                    call facet_data => {assert => {pass => 1, details => 'test 3'}};
                };
                event '+Test2::Harness::Event' => sub {
                    call facet_data => {plan => {count => 3}};
                };
                end;
            },
            "Got events as list"
        );

        is(
            [$job->stdout],
            [
                "stdout line 1\n",
                "stdout line 2\n",
                "stdout line 3\n",
            ],
            "Got all stdout lines"
        );

        is(
            [$job->stderr],
            [
                "stderr line 1\n",
                "stderr line 2\n",
                "stderr line 3\n",
            ],
            "Got all stderr lines"
        );
        is(
            [$job->muxed],
            [
                {stamp => 12345, fileno => 1, buffer => "stdout line 1\n"},
                {stamp => 12345, fileno => 1, buffer => "stderr line 1\n"},
                {stamp => 12345, fileno => 1, buffer => "stdout line 2\n"},
                {stamp => 12345, fileno => 1, buffer => "stderr line 2\n"},
                {stamp => 12345, fileno => 1, buffer => "stdout line 3\n"},
                {stamp => 12345, fileno => 1, buffer => "stderr line 3\n"},
            ],
            "Got all muxed lines"
        );
    };

    is($one->TO_JSON, {%{$make_data->()}, system_env_vars => \%ENV}, "Serialization cycle");

    my ($fh, $filename) = tempfile(TMPDIR => 1);
    close($fh);
    $one->save($filename);
    my $two = $CLASS->new(file => $filename);
    is($one->TO_JSON, $two->TO_JSON, "Saving and loading test");
    unlink($filename);
};

subtest dir => sub {
    my $dir = tempdir(CLEANUP => 1, TMPDIR => 1);
    my $one = $CLASS->new(dir => $dir, id => 111);

    is($one->jobs(), [], "No jobs yet");

    mkdir($one->path('123')) or die "Could not make dir: $!";
    my $j1 = $one->add_job(Test2::Harness::Run::Job->new(id => 123, test_file => 'foo.t', dir => $one->path('123')));
    is(
        $one->jobs(),
        [
            { %$j1, __FROM__ => T()}, # Well, a clone anyway
        ],
        "Job 1"
    );

    mkdir($one->path('124')) or die "Could not make dir: $!";
    my $j2 = $one->add_job(Test2::Harness::Run::Job->new(id => 124, test_file => 'bar.t', dir => $one->path('124')));
    is(
        $one->jobs(),
        [
            { %$j1, __FROM__ => T() }, # Well, a clone anyway
            { %$j2, __FROM__ => T() }, # Well, a clone anyway
        ],
        "Job 2"
    );

    mkdir($one->path('125')) or die "Could not make dir: $!";
    my $j3 = $one->add_job(Test2::Harness::Run::Job->new(id => 125, test_file => 'baz.t', dir => $one->path('125')));
    is(
        $one->jobs(),
        [
            { %$j1, __FROM__ => T() }, # Well, a clone anyway
            { %$j2, __FROM__ => T() }, # Well, a clone anyway
            { %$j3, __FROM__ => T() }, # Well, a clone anyway
        ],
        "Job 3"
    );

    my $env = {
        HARNESS_JOBS        => 1,
        PERL_USE_UNSAFE_INC => 1,
        T2_HARNESS_JOBS     => 1,
        T2_HARNESS_RUN_DIR  => $dir,
        T2_HARNESS_RUN_ID   => 111,
    };

    my $job_env = {
        TMP                 => T(),
        TEMP                => T(),
        TMPDIR              => T(),
        TEMPDIR             => T(),
    };

    is(
        $one->TO_JSON,
        {
            id              => 111,
            job_count       => 1,
            switches        => [],
            libs            => [],
            lib             => 0,
            blib            => 0,
            preload         => undef,
            output_merging  => 0,
            event_stream    => 1,
            chdir           => undef,
            search          => ['t'],
            unsafe_inc      => 1,
            env_vars        => $env,
            system_env_vars => \%ENV,

            jobs => [
                {
                    events      => [],
                    exit        => undef,
                    id          => 123,
                    muxed       => [],
                    pid         => undef,
                    start_stamp => undef,
                    stop_stamp  => undef,
                    stderr      => [],
                    stdout      => [],
                    test_file   => 'foo.t',
                    env_vars    => $job_env,
                },
                {
                    events      => [],
                    exit        => undef,
                    id          => 124,
                    muxed       => [],
                    pid         => undef,
                    start_stamp => undef,
                    stop_stamp  => undef,
                    stderr      => [],
                    stdout      => [],
                    test_file   => 'bar.t',
                    env_vars    => $job_env,
                },
                {
                    events      => [],
                    exit        => undef,
                    id          => 125,
                    muxed       => [],
                    pid         => undef,
                    start_stamp => undef,
                    stop_stamp  => undef,
                    stderr      => [],
                    stdout      => [],
                    test_file   => 'baz.t',
                    env_vars    => $job_env,
                }
            ]
        },
        "Serialized"
    );

    is(
        $one->config_data,
        {
            blib           => 0,
            chdir          => undef,
            event_stream   => 1,
            id             => 111,
            job_count      => 1,
            lib            => 0,
            libs           => [],
            output_merging => 0,
            preload        => undef,
            search         => ['t'],
            switches       => [],
            unsafe_inc     => 1,

            env_vars => {
                T2_HARNESS_JOBS     => 1,
                T2_HARNESS_RUN_DIR  => $dir,
                T2_HARNESS_RUN_ID   => 111,
                PERL_USE_UNSAFE_INC => 1,
                HARNESS_JOBS        => 1
            },
        },
        "Config data",
    );

    $one->save_config;
    ok(-e $one->path('config.json'), "wrote file");

    my $three = $CLASS->new(
        path        => $one->path,
        load_config => 1,
    );

    is($one->config_data, $three->config_data, "Stored and retrieved config data");
};

subtest all_libs => sub {
    my $one = $CLASS->new(
        data => {},
        id => 1,
        libs => ['foo', 'bar'],
        lib  => 1,
        blib => 1,
    );

    is(
        [$one->all_libs],
        ['lib', 'blib/lib', 'blib/arch', 'foo', 'bar'],
        "Got all libs paths"
    );

    $one->{lib} = 0;
    $one->{blib} = 0;

    is([$one->all_libs], ['foo', 'bar'], "no lib or blib");

    $one->{lib} = 1;
    $one->{blib} = 1;
    $one->{libs} = [];

    is(
        [$one->all_libs],
        ['lib', 'blib/lib', 'blib/arch'],
        "No added paths"
    );
};

subtest find_tests => sub {
    my $one = $CLASS->new(
        data => {},
        id => 1,
    );

    is(
        [$one->find_tests],
        [
            map { Test2::Harness::Worker::TestFile->new(filename => $_) }
            sort { $a cmp $b } qw{
t/Test2/Formatter/Stream.t
t/Test2/Harness/Util/JSON.t
t/Test2/Harness/Util/File/JSON.t
t/Test2/Harness/Util/File/Stream.t
t/Test2/Harness/Util/File/Value.t
t/Test2/Harness/Util/File/JSONL.t
t/Test2/Harness/Util/File.t
t/Test2/Harness/Util/Proc.t
t/Test2/Harness/Util/HashBase.t
t/Test2/Harness/Event.t
t/Test2/Harness/TestFile.t
t/Test2/Harness/Run/Worker.t
t/Test2/Harness/Run/Job.t
t/Test2/Harness/Run.t
t/Test2/Harness/Util.t
t/Test2/Harness.t
t/HashBase.t
t/simple.t
            },
        ],
        "Found all of our tests"
    );
};

subtest perl_command => sub {
    my $one = $CLASS->new(
        data => {},
        id => 1,
        libs => ['foo', 'bar'],
        lib  => 1,
        blib => 1,

        switches => ['-e', 'print "Hi!"', '-T'],
    );

    is(
        [$one->perl_command],
        [
            $^X,
            '-e', 'print "Hi!"', '-T',
            qw{-Ilib -Iblib/lib -Iblib/arch -Ifoo -Ibar},
        ],
        "Got perl command"
    );

    require Test2::Harness;
    require File::Spec;
    my $harness_path = $INC{"Test2/Harness.pm"};
    $harness_path =~ s{Test2/Harness\.pm$}{};
    $harness_path = File::Spec->rel2abs($harness_path);

    is(
        [$one->perl_command(include_harness_lib => 1)],
        [
            $^X,
            '-e', 'print "Hi!"', '-T',
            "-I$harness_path",
            qw{-Ilib -Iblib/lib -Iblib/arch -Ifoo -Ibar},
        ],
        "Got perl command with harness lib in path"
    );
};

done_testing;
