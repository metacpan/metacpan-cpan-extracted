use Test2::V0 -no_srand => 1;
use v5.42;
use Test::JSON::Diff qw( json_eq_or_diff );
use File::Which ();
use Path::Tiny qw( tempdir );

sub run_check (@args) {
    my $ret;
    my $events = intercept { $ret = json_eq_or_diff(@args) };
    my @results = $events->squash_info->flatten->@*;
    is scalar @results, 1, 'exactly one assertion';
    my $result = $results[0];
    # first diag is the standard "Failed test" message
    my $diag = $result->{diag} ? $result->{diag}->[1] : undef;
    return ($ret, $result, $diag);
}

package Test::JSON::Diff::NoImport {
    use Test::JSON::Diff;
}

subtest 'export' => sub {
    ok main->can('json_eq_or_diff'), 'imported on request';
    ok !Test::JSON::Diff::NoImport->can('json_eq_or_diff'), 'not exported by default';
};

subtest 'same' => sub {
    foreach my $case (
        [ '{"a":"b","c":"d"}',            '{"c":"d","a":"b"}',                 'key order'       ],
        [ '{"a":"b"}',                    qq({ "a" :\t"b"\n}\n),               'whitespace'      ],
        [ '{"x":{"z":[1,{"q":1,"p":2}],"y":null}}', '{"x":{"y":null,"z":[1,{"p":2,"q":1}]}}', 'nested' ],
        [ '[true,false,null]',            '[ true, false, null ]',             'literals'        ],
        [ '12345678901234567890',         '12345678901234567890',              'big integer'     ],
        [ '"a b"',                        '"a b"',                             'string scalar'   ],
        [ qq({"\xc3\xa9":"\xe2\x98\x83"}), qq({ "\xc3\xa9" : "\xe2\x98\x83" }), 'utf-8'          ],
    ) {
        my($actual, $expected, $name) = @$case;
        my($ret, $result) = run_check($actual, $expected, $name);
        is $ret, T(), "$name: returns true";
        is $result, hash { field pass => 1; field name => $name; etc; }, "$name: passes";
    }
};

subtest 'different' => sub {
    foreach my $case (
        [ '[1]',                     '["1"]',                    'number vs string'  ],
        [ '[true]',                  '[1]',                      'boolean vs number' ],
        [ '[null]',                  '[""]',                     'null vs string'    ],
        [ '[1,2]',                   '[2,1]',                    'array order'       ],
        [ '[1]',                     '[1.0]',                    'number literal'    ],
        [ '12345678901234567890',    '12345678901234567891',     'big integer'       ],
        [ '{"a":1}',                 '{"a":1,"b":2}',            'missing key'       ],
        [ '{"a":"b "}',              '{"a":"b"}',                'quoted whitespace' ],
    ) {
        my($actual, $expected, $name) = @$case;
        my($ret, $result, $diag) = run_check($actual, $expected, $name);
        is $ret, F(), "$name: returns false";
        is $result, hash { field pass => 0; field name => $name; etc; }, "$name: fails";
        like $diag, qr/^--- expected\n\+\+\+ actual\n\@\@/, "$name: diag is a unified diff";
    }
};

subtest 'diff diagnostic' => sub {
    my($ret, $result, $diag) = run_check('{"b":[1,2,3],"a":1}', '{"a":1,"b":[1,"2",3]}');
    is $diag, join("\n",
        '--- expected',
        '+++ actual',
        '@@ -2,7 +2,7 @@',
        '   "a": 1,',
        '   "b": [',
        '     1,',
        '-    "2",',
        '+    2,',
        '     3',
        '   ]',
        ' }',
    ), 'pretty printed, key sorted, expected then actual';
};

subtest 'default test name' => sub {
    my($ret, $result) = run_check('1', '1');
    is $result->{name}, 'json is the same';
    ($ret, $result) = run_check('1', '1', undef);
    is $result->{name}, 'json is the same', 'undef name';
    ($ret, $result) = run_check('1', '1', { context => 1 });
    is $result->{name}, 'json is the same', 'options only';
    ($ret, $result) = run_check('1', '1', 'foo', { context => 1 });
    is $result->{name}, 'foo', 'name and options';
};

subtest 'context' => sub {
    my $expected = '[' . join(',', 1..20) . ']';
    my $actual   = '[' . join(',', 1..9, 'false', 11..20) . ']';

    my(undef, undef, $diag) = run_check($actual, $expected);
    my @lines = split /\n/, $diag;
    is scalar(grep /^ /, @lines), 6, 'default context is 3';

    (undef, undef, $diag) = run_check($actual, $expected, { context => 0 });
    @lines = split /\n/, $diag;
    is \@lines, ['--- expected', '+++ actual', '@@ -11 +11 @@', '-  10,', '+  false,'], 'context 0';

    (undef, undef, $diag) = run_check($actual, $expected, { context => 5 });
    @lines = split /\n/, $diag;
    is scalar(grep /^ /, @lines), 10, 'context 5';
};

subtest 'max_lines' => sub {
    my $expected = '[' . join(',', 1..200) . ']';
    my $actual   = '[' . join(',', map { "\"$_\"" } 1..200) . ']';

    my(undef, undef, $diag) = run_check($actual, $expected);
    my @lines = split /\n/, $diag;
    is scalar @lines, 51, 'default is 50 lines plus ...';
    is $lines[0], '--- expected', 'header counts';
    is $lines[-1], '...', 'clipped';

    (undef, undef, $diag) = run_check($actual, $expected, { max_lines => 5 });
    is [split /\n/, $diag], ['--- expected', '+++ actual', '@@ -1,202 +1,202 @@', ' [', '-  1,', '...'], 'max_lines 5';

    (undef, undef, $diag) = run_check('[2]', '[1]', { max_lines => 7 });
    is [split /\n/, $diag], ['--- expected', '+++ actual', '@@ -1,3 +1,3 @@', ' [', '-  1', '+  2', ' ]'], 'exactly max_lines is not clipped';

    (undef, undef, $diag) = run_check('[2]', '[1]', { max_lines => 6 });
    is [split /\n/, $diag], ['--- expected', '+++ actual', '@@ -1,3 +1,3 @@', ' [', '-  1', '+  2', '...'], 'one over max_lines is clipped';
};

subtest 'invalid json' => sub {
    foreach my $case (
        [ '{"a":',  'unfinished'      ],
        [ '',       'empty'           ],
        [ '1 2',    'multiple values' ],
        [ '{a:1}',  'unquoted key'    ],
    ) {
        my($bad, $name) = @$case;

        my($ret, $result, $diag) = run_check($bad, '1');
        is $ret, F(), "$name actual: returns false";
        like $diag, qr/^actual is not valid JSON:\njq: /, "$name actual: diag";
        unlike $diag, qr/expected is not valid/, "$name actual: expected is fine";

        ($ret, $result, $diag) = run_check('1', $bad);
        is $ret, F(), "$name expected: returns false";
        like $diag, qr/^expected is not valid JSON:\njq: /, "$name expected: diag";
    }

    my(undef, undef, $diag) = run_check('1 2', '');
    like $diag, qr/^actual is not valid JSON:\n.*exactly one JSON value.*\nexpected is not valid JSON:\n.*exactly one JSON value/s, 'both';
};

subtest 'usage errors' => sub {
    like dies { json_eq_or_diff('1', '1', { foo => 1, bar => 2 }) },
        qr/^json_eq_or_diff: unknown option\(s\): bar, foo at /, 'unknown options';
    like dies { json_eq_or_diff('1', '1', 'name', { foo => 1 }) },
        qr/^json_eq_or_diff: unknown option\(s\): foo at /, 'unknown option with name';
    like dies { json_eq_or_diff('1', '1', 'name', 'extra') },
        qr/^usage: /, 'fourth argument not a hash';
    like dies { json_eq_or_diff('1', '1', 'name', {}, {}) },
        qr/^usage: /, 'too many arguments';
    like dies { json_eq_or_diff('1', '1', { context => -1 }) },
        qr/context must be a non-negative integer/, 'bad context';
    like dies { json_eq_or_diff('1', '1', { max_lines => 0 }) },
        qr/max_lines must be a positive integer/, 'bad max_lines';
};

subtest 'insulated from caller $/' => sub {
    # a caller that has left $/ in slurp mode (or any non-default value)
    # shouldn't affect _diff's own line-based reading of the diff subprocess's
    # output -- in particular, with $/ undef, reading an already-at-EOF pipe
    # returns an empty string once instead of undef immediately, which used
    # to be misread as a single (phantom) line of diff output, producing a
    # false failure for two documents that are actually the same.
    foreach my $sep ( undef, '', "\x00" ) {
        local $/ = $sep;
        my $sep_name = defined $sep ? ( length $sep ? "chr(" . ord($sep) . ")" : "''" ) : 'undef';

        my ($ret) = run_check( '{"a":1,"b":2}', '{"b":2,"a":1}', "same despite \$/ = $sep_name" );
        is $ret, T(), "still detects equal JSON when caller left \$/ = $sep_name";

        my ( undef, undef, $diag ) = run_check( '[1,2]', '[2,1]', "different despite \$/ = $sep_name" );
        like $diag, qr/^--- expected\n\+\+\+ actual\n\@\@/,
          "still produces a real diagnostic for an actual difference when \$/ = $sep_name";
    }
};

subtest 'missing tools' => sub {
    my $jq = File::Which::which('jq');

    {
        local $ENV{PATH} = '';
        like dies { json_eq_or_diff('1', '1') }, qr/^json_eq_or_diff: unable to find jq at /, 'no jq';
    }

    my $dir = tempdir;
    symlink $jq, $dir->child("jq") or die "unable to symlink $jq: $!";
    {
        local $ENV{PATH} = "$dir";
        like dies { json_eq_or_diff('1', '1') }, qr/^json_eq_or_diff: unable to find diff at /, 'no diff';
    }
};

done_testing;
