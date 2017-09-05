use Test2::Bundle::Extended -target => 'Test2::Harness::Run::Job';

use ok $CLASS;

use Scalar::Util qw/blessed/;
use File::Temp qw/tempdir/;

subtest construction => sub {
    like(dies { $CLASS->new }, qr/^One of 'dir', 'data', 'file' or 'path' is required/, "Must provide data somehow");
    like(dies { $CLASS->new(data => {}) }, qr/The 'id' attribute is required/, "Must provide data somehow");
    like(dies { $CLASS->new(data => {}, id => 1) }, qr/One of 'test_file' or 'test' must be specified/, "Must provide data somehow");

    ok($CLASS->new(data => {}, id => 1, test_file => 1), "Construction works");
    ok($CLASS->new(data => {id => 1, test_file => 1}), "id and test file can come from data");
};

subtest path => sub {
    my $one = $CLASS->new(dir => '/fake/dir/for/test', id => 1, test_file => 1, no_tmp => 1);
    is($one->path, '/fake/dir/for/test', "no args gives root dir");
    is($one->path('a'), File::Spec->catfile('/fake/dir/for/test', 'a'), "Found file 'a'");
    is($one->path('a', 'b'), File::Spec->catfile('/fake/dir/for/test', 'a', 'b'), "Found file 'a/b'");

    my $two = $CLASS->new(data => {}, id => 1, test_file => 1);
    like(dies { $two->path }, qr/'path' only works when using a directory/, "Cannot use path with non-dir");
};

subtest data => sub {
    my $make_data = sub {
        {
            id        => 123,
            test_file => 'foo.t',
            events    => [
                { facets => {assert => {pass  => 1, details => 'test 1'}}, __FROM__ => 'fake'},
                { facets => {assert => {pass  => 1, details => 'test 2'}}, __FROM__ => 'fake'},
                { facets => {assert => {pass  => 1, details => 'test 3'}}, __FROM__ => 'fake'},
                { facets => {plan   => {count => 3}}, __FROM__ => 'fake'},
            ],
            pid   => $$,
            start_stamp => 12345,
            stop_stamp => 12346,
            exit  => 127,
            muxed => [
                { stamp => 12345, fileno => 1, buffer => "stdout line 1\n" },
                { stamp => 12345, fileno => 1, buffer => "stderr line 1\n" },
                { stamp => 12345, fileno => 1, buffer => "stdout line 2\n" },
                { stamp => 12345, fileno => 1, buffer => "stderr line 2\n" },
                { stamp => 12345, fileno => 1, buffer => "stdout line 3\n" },
                { stamp => 12345, fileno => 1, buffer => "stderr line 3\n" },
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
            env_vars => {},
        };
    };

    my $data = $make_data->();
    my $one = $CLASS->new(data => $data);

    is($one->pid,   $$,    "got pid");
    is($one->start_stamp, 12345, "got stamp");
    is($one->stop_stamp, 12346, "got stamp");
    is($one->exit,  127,   "got exit");

    is($one->id,        123,     "got id");
    is($one->test_file, 'foo.t', "got test file");
    like(
        [$one->poll_events],
        array {
            event '+Test2::Harness::Event' => sub {
                call facet_data => {assert => {pass => 1, details => 'test 1'}};
                call from_line => T();
            };
            event '+Test2::Harness::Event' => sub {
                call facet_data => {assert => {pass => 1, details => 'test 2'}};
                call from_line => T();
            };
            event '+Test2::Harness::Event' => sub {
                call facet_data => {assert => {pass => 1, details => 'test 3'}};
                call from_line => T();
            };
            event '+Test2::Harness::Event' => sub {
                call facet_data => {plan => {count => 3}};
                call from_line => T();
            };
            end;
        },
        "Got events via poll"
    );

    is(
        [$one->poll_events],
        [],
        "No new events, so nothing from a second poll"
    );

    like(
        [$one->events],
        array {
            event '+Test2::Harness::Event' => sub {
                call facet_data => {assert => {pass => 1, details => 'test 1'}};
                call from_line => T();
            };
            event '+Test2::Harness::Event' => sub {
                call facet_data => {assert => {pass => 1, details => 'test 2'}};
                call from_line => T();
            };
            event '+Test2::Harness::Event' => sub {
                call facet_data => {assert => {pass => 1, details => 'test 3'}};
                call from_line => T();
            };
            event '+Test2::Harness::Event' => sub {
                call facet_data => {plan => {count => 3}};
                call from_line => T();
            };
            end;
        },
        "Got events as list"
    );

    is(
        [$one->stdout],
        [
            "stdout line 1\n",
            "stdout line 2\n",
            "stdout line 3\n",
        ],
        "Got all stdout lines"
    );
    is(
        [$one->poll_stdout],
        [
            "stdout line 1\n",
            "stdout line 2\n",
            "stdout line 3\n",
        ],
        "Got all stdout lines via poll"
    );
    is([$one->poll_stdout], [], "no more lines to poll");

    is(
        [$one->stderr],
        [
            "stderr line 1\n",
            "stderr line 2\n",
            "stderr line 3\n",
        ],
        "Got all stderr lines"
    );
    is(
        [$one->poll_stderr],
        [
            "stderr line 1\n",
            "stderr line 2\n",
            "stderr line 3\n",
        ],
        "Got all stderr lines via poll"
    );
    is([$one->poll_stderr], [], "no more lines to poll");

    is(
        [$one->muxed],
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
    is(
        [$one->poll_muxed],
        [
            {stamp => 12345, fileno => 1, buffer => "stdout line 1\n"},
            {stamp => 12345, fileno => 1, buffer => "stderr line 1\n"},
            {stamp => 12345, fileno => 1, buffer => "stdout line 2\n"},
            {stamp => 12345, fileno => 1, buffer => "stderr line 2\n"},
            {stamp => 12345, fileno => 1, buffer => "stdout line 3\n"},
            {stamp => 12345, fileno => 1, buffer => "stderr line 3\n"},
        ],
        "Got all muxed lines via poll"
    );
    is([$one->poll_muxed], [], "no more lines to poll");

    is($one->TO_JSON, $make_data->(), "Serializes back to the original");

    is($data, $make_data->(), "Data has not changed noticably");
    ok(!(grep { blessed($_) } @{$data->{events}}), "Did not bless event data");
};

subtest dir => sub {
    my $dir = tempdir(CLEANUP => 1, TMPDIR => 1);
    my $temp = $CLASS->new(dir => $dir, id => 123, test_file => 'foo.t');

    $temp->events_file->write(
        {facets => {assert => {pass  => 1,   details  => 'test 1'}}},
        {facets => {assert => {pass  => 1,   details  => 'test 2'}}},
        {facets => {assert => {pass  => 1,   details  => 'test 3'}}},
        {facets => {plan   => {count => 3}}},
    );

    $temp->stdout_file->write(<<'    EOT');
stdout line 1
stdout line 2
stdout line 3
    EOT

    $temp->stderr_file->write(<<'    EOT');
stderr line 1
stderr line 2
stderr line 3
    EOT

    $temp->muxed_file->write(
        {stamp => 12345, fileno => 1, buffer => "stdout line 1\n"},
        {stamp => 12345, fileno => 1, buffer => "stderr line 1\n"},
        {stamp => 12345, fileno => 1, buffer => "stdout line 2\n"},
        {stamp => 12345, fileno => 1, buffer => "stderr line 2\n"},
        {stamp => 12345, fileno => 1, buffer => "stdout line 3\n"},
        {stamp => 12345, fileno => 1, buffer => "stderr line 3\n"},
    );

    $temp->set_pid($$);
    $temp->set_start_stamp(12345);
    $temp->set_stop_stamp(12346);
    $temp->set_exit(127);

    $temp = undef;

    my $one = $CLASS->new(dir => $dir, id => 123, test_file => 'foo.t');
    is($one->pid,         $$,    "got pid");
    is($one->start_stamp, 12345, "got stamp");
    is($one->stop_stamp,  12346, "got stamp");
    is($one->exit,        127,   "got exit");

    is($one->id,        123,     "got id");
    is($one->test_file, 'foo.t', "got test file");
    like(
        [$one->poll_events],
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
        "Got events via poll"
    );

    is(
        [$one->poll_events],
        [],
        "No new events, so nothing from a second poll"
    );

    like(
        [$one->events],
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
        [$one->stdout],
        [
            "stdout line 1\n",
            "stdout line 2\n",
            "stdout line 3\n",
        ],
        "Got all stdout lines"
    );
    is(
        [$one->poll_stdout],
        [
            "stdout line 1\n",
            "stdout line 2\n",
            "stdout line 3\n",
        ],
        "Got all stdout lines via poll"
    );
    is([$one->poll_stdout], [], "no more lines to poll");

    is(
        [$one->stderr],
        [
            "stderr line 1\n",
            "stderr line 2\n",
            "stderr line 3\n",
        ],
        "Got all stderr lines"
    );
    is(
        [$one->poll_stderr],
        [
            "stderr line 1\n",
            "stderr line 2\n",
            "stderr line 3\n",
        ],
        "Got all stderr lines via poll"
    );
    is([$one->poll_stderr], [], "no more lines to poll");

    is(
        [$one->muxed],
        [
            {stamp => 12345, fileno => 1, buffer => "stdout line 1\n", __FROM__ => T()},
            {stamp => 12345, fileno => 1, buffer => "stderr line 1\n", __FROM__ => T()},
            {stamp => 12345, fileno => 1, buffer => "stdout line 2\n", __FROM__ => T()},
            {stamp => 12345, fileno => 1, buffer => "stderr line 2\n", __FROM__ => T()},
            {stamp => 12345, fileno => 1, buffer => "stdout line 3\n", __FROM__ => T()},
            {stamp => 12345, fileno => 1, buffer => "stderr line 3\n", __FROM__ => T()},
        ],
        "Got all muxed lines"
    );
    is(
        [$one->poll_muxed],
        [
            {stamp => 12345, fileno => 1, buffer => "stdout line 1\n", __FROM__ => T()},
            {stamp => 12345, fileno => 1, buffer => "stderr line 1\n", __FROM__ => T()},
            {stamp => 12345, fileno => 1, buffer => "stdout line 2\n", __FROM__ => T()},
            {stamp => 12345, fileno => 1, buffer => "stderr line 2\n", __FROM__ => T()},
            {stamp => 12345, fileno => 1, buffer => "stdout line 3\n", __FROM__ => T()},
            {stamp => 12345, fileno => 1, buffer => "stderr line 3\n", __FROM__ => T()},
        ],
        "Got all muxed lines via poll"
    );
    is([$one->poll_muxed], [], "no more lines to poll");

    is(
        $one->TO_JSON,
        {
            id        => 123,
            test_file => 'foo.t',
            events    => [
                {facets => {assert => {pass => 1, details => 'test 1'}}, __FROM__ => T()},
                {facets => {assert => {pass => 1, details => 'test 2'}}, __FROM__ => T()},
                {facets => {assert => {pass => 1, details => 'test 3'}}, __FROM__ => T()},
                {facets => {plan => {count => 3}}, __FROM__ => T()},

            ],
            pid         => $$,
            start_stamp => 12345,
            stop_stamp  => 12346,
            exit        => 127,
            muxed       => [
                {stamp => 12345, fileno => 1, buffer => "stdout line 1\n", __FROM__ => T()},
                {stamp => 12345, fileno => 1, buffer => "stderr line 1\n", __FROM__ => T()},
                {stamp => 12345, fileno => 1, buffer => "stdout line 2\n", __FROM__ => T()},
                {stamp => 12345, fileno => 1, buffer => "stderr line 2\n", __FROM__ => T()},
                {stamp => 12345, fileno => 1, buffer => "stdout line 3\n", __FROM__ => T()},
                {stamp => 12345, fileno => 1, buffer => "stderr line 3\n", __FROM__ => T()},
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
            env_vars => {
                TMP     => T(),
                TEMP    => T(),
                TMPDIR  => T(),
                TEMPDIR => T(),
            },
        },
        "Serializes as expected"
    );
};

done_testing;
