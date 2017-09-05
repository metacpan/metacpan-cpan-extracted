use Test2::V0 -target => 'Test2::Harness::Schema::WorkDir::TAP';

use ok $CLASS => qw/parse_stdout_tap parse_stderr_tap/;

imported_ok(qw/parse_stdout_tap parse_stderr_tap/);

subtest stderr => sub {
    ok(!parse_stderr_tap('anything at all'), "Not TAP if STDERR is not prefixed with #");

    my $facet_data = parse_stderr_tap("# anything that is prefixed with a #\n");

    is(
        $facet_data,
        {
            trace => {nested => 0},
            info  => [
                {
                    debug   => 1,
                    details => 'anything that is prefixed with a #',
                    tag     => 'DIAG'
                }
            ],

        },
        "Got Expected facet data"
    );

    $facet_data = parse_stderr_tap("        # anything that is prefixed with a #");
    is(
        $facet_data,
        {
            trace => {nested => 2},
            info  => [
                {
                    debug   => 1,
                    details => 'anything that is prefixed with a #',
                    tag     => 'DIAG'
                }
            ],

        },
        "Works when indented and lacking a newline"
    );

};

subtest stdout => sub {
    subtest indent => sub {
        my $facet_data = parse_stdout_tap("      # foo");
        is($facet_data->{trace}->{nested}, 1, "4 spaces = 1 nest, extra spaces ignored");

        $facet_data = parse_stdout_tap("\t# foo");
        is($facet_data->{trace}->{nested}, 1, "1 tab = 1 nest");
    };

    subtest not_tap => sub {
        my $facet_data = parse_stdout_tap("hello there");
        is($facet_data, undef, "No facet data, not TAP");
    };

    subtest buffered_subtest => sub {
        my $facet_data = parse_stdout_tap("}");
        is(
            $facet_data,
            {parent => {}, harness => {subtest_end => 1}, trace => {nested => 0}},
            "Got subtest end",
        );

        $facet_data = parse_stdout_tap("ok {");
        is(
            $facet_data,
            {
                'harness' => {'subtest_start' => 1},
                'trace'   => {'nested'        => 0},
                'parent'  => {'details'       => ''},
                'assert'  => {'no_debug'      => 1, 'details' => '', 'pass' => 1},
            },
            "Most simple buffered subtest start"
        );

        $facet_data = parse_stdout_tap("ok foo {");
        is(
            $facet_data,
            {
                'harness' => {'subtest_start' => 1},
                'trace'   => {'nested'        => 0},
                'parent'  => {'details'       => 'foo'},
                'assert'  => {'no_debug'      => 1, 'details' => 'foo', 'pass' => 1},
            },
            "named buffered subtest start"
        );

        $facet_data = parse_stdout_tap("ok 5 - foo { # todo xxx");
        is(
            $facet_data,
            {
                'harness' => {'subtest_start' => 1},
                'trace'   => {'nested'        => 0},
                'parent'  => {'details'       => 'foo'},
                'assert'  => {'no_debug'      => 1, 'details' => 'foo', 'pass' => 1, number => 5},
                'amnesty' => [{'details' => 'xxx', 'tag' => 'TODO'}],
            },
            "complicated"
        );
    };

    subtest parse_tap_version => sub {
        my $facet_data = parse_stdout_tap("TAP version 13");
        is(
            $facet_data,
            {
                about => {details => "TAP version 13"},
                info  => [{tag   => 'INFO', debug => 0, details => "TAP version 13"}],
                trace => {nested => 0},
            },
            "Parsed TAP version"
        );
    };

    subtest parse_tap_bail => sub {
        my $facet_data = parse_stdout_tap("Bail out!");
        is(
            $facet_data,
            {
                control => { halt => 1, details => '' },
                trace => {nested => 0},
            },
            "Bail out without reason"
        );

        $facet_data = parse_stdout_tap("Bail out!  xyz");
        is(
            $facet_data,
            {
                control => { halt => 1, details => 'xyz' },
                trace => {nested => 0},
            },
            "Bail out with reason (extraleading space removed)"
        );
    };

    subtest parse_tap_comment => sub {
        my $facet_data = parse_stdout_tap('#foo bar baz');
        is(
            $facet_data,
            {
                trace => { nested => 0 },
                info => [{tag => 'NOTE', details => 'foo bar baz', debug => 0}],
            },
            "Parsed comment (no space)"
        );

        $facet_data = parse_stdout_tap('# foo bar baz');
        is(
            $facet_data,
            {
                trace => { nested => 0 },
                info => [{tag => 'NOTE', details => 'foo bar baz', debug => 0}],
            },
            "Parsed comment (with space)"
        );
    };

    subtest parse_tap_plan => sub {
        is(
            parse_stdout_tap('1..5'),
            {
                trace => { nested => 0 },
                plan => { count => 5, skip => 0, details => undef },
            },
            "Simple plan"
        );

        is(
            parse_stdout_tap('1..0'),
            {
                trace => { nested => 0 },
                plan => { count => 0, skip => 1, details => "no reason given" },
            },
            "no reason skip"
        );

        is(
            parse_stdout_tap('1..0 # SKIP foo bar baz'),
            {
                trace => { nested => 0 },
                plan => { count => 0, skip => 1, details => "foo bar baz" },
            },
            "skip with reason"
        );

        is(
            parse_stdout_tap('1..5 blah'),
            {
                trace => { nested => 0 },
                plan => { count => 5, skip => 0, details => undef },
                info => [{details => 'Extra characters after plan.', debug => 1, tag => 'PARSER'}],
            },
            "Plan parse error"
        );
    };

    subtest parse_tap_ok => sub {
        is(
            parse_stdout_tap('ok'),
            {
                assert => { pass => T(), details => '', no_debug => 1 },
                trace => {nested => 0},
            },
            "Simple ok"
        );

        is(
            parse_stdout_tap('not ok'),
            {
                assert => { pass => F(), details => '', no_debug => 1 },
                trace => {nested => 0},
            },
            "Simple not ok"
        );

        is(
            parse_stdout_tap('ok 5 - foo bar baz'),
            {
                assert => { pass => T(), details => 'foo bar baz', no_debug => 1, number => 5 },
                trace => {nested => 0},
            },
            "Named and numbered"
        );

        is(
            parse_stdout_tap('ok 5 Subtest: foo bar baz # ToDo & SkIp because!'),
            {
                assert => { pass => T(), details => 'Subtest: foo bar baz', no_debug => 1, number => 5 },
                parent => {details => 'foo bar baz'},
                trace => {nested => 0},
                amnesty => [
                    {tag => 'SKIP', details => 'because!'},
                    {tag => 'TODO', details => 'because!'},
                ],
            },
            "All the (valid) things!"
        );

        is(
            parse_stdout_tap('ok 5 Subtest:'),
            {
                assert => { pass => T(), details => 'Subtest:', no_debug => 1, number => 5 },
                parent => {details => 1},
                trace => {nested => 0},
            },
            "Nameless subtest"
        );

        is(
            parse_stdout_tap('ok- foo'),
            {
                assert => { pass => T(), details => 'foo', no_debug => 1 },
                trace => {nested => 0},
                info => [{tag => 'PARSER', details => "'ok' is not immediately followed by a space.", debug => 1}],
            },
            "No space after ok"
        );

        is(
            parse_stdout_tap('ok  5 foo'),
            {
                assert => { pass => T(), details => 'foo', no_debug => 1, number => 5 },
                trace => {nested => 0},
                info => [{tag => 'PARSER', details => "Extra space after 'ok'", debug => 1}],
            },
            "Extra space after ok"
        );

        is(
            parse_stdout_tap('ok 5 foo#todofoo'),
            {
                assert => {pass   => T(), details => 'foo', no_debug => 1, number => 5},
                trace  => {nested => 0},
                amnesty => [{tag => 'TODO', details => 'foo'}],
                info    => [
                    {tag => 'PARSER', details => "No space before the '#' for the 'todo' directive.", debug => 1},
                    {tag => 'PARSER', details => "No space between 'todo' directive and reason.",     debug => 1},
                ],
            },
            "Directive spacing"
        );

    };
};

done_testing;
