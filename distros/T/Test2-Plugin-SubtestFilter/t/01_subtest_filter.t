use Test2::V0;

use lib 't/lib';
use TestHelper;

my $test_file = 't/examples/basic.t';

my @tests = (
    {
        name => 'no SUBTEST_FILTER - all tests run',
        filter => undef,
        expect => {
            'foo'                       => 'executed',
            'foo > nested arithmetic'   => 'executed',
            'foo > nested string'       => 'executed',
            'bar'                       => 'executed',
            'baz'                       => 'executed',
            'baz > nested deep'         => 'executed',
            'baz > nested deep > nested very deep' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER=foo - matches foo only',
        filter => 'foo',
        expect => {
            'foo'                       => 'executed',
            'foo > nested arithmetic'   => 'executed',
            'foo > nested string'       => 'executed',
            'bar'                       => 'skipped',
            'baz'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=bar - matches bar only',
        filter => 'bar',
        expect => {
            'foo'                       => 'skipped',
            'bar'                       => 'executed',
            'baz'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with substring pattern ba - matches bar and baz',
        filter => 'ba',
        expect => {
            'foo'                       => 'skipped',
            'bar'                       => 'executed',
            'baz'                       => 'executed',
            'baz > nested deep'         => 'executed',
            'baz > nested deep > nested very deep' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER for nested child with space-separated path',
        filter => 'foo nested arithmetic',
        expect => {
            'foo'                       => 'executed',
            'foo > nested arithmetic'   => 'executed',
            'foo > nested string'       => 'skipped',
            'bar'                       => 'skipped',
            'baz'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER for deeply nested child with partial substring',
        filter => 'nested very deep',
        expect => {
            'foo'                       => 'skipped',
            'bar'                       => 'skipped',
            'baz'                       => 'executed',
            'baz > nested deep'         => 'executed',
            'baz > nested deep > nested very deep' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER="nested arithmetic" - explores top level for multi-word',
        filter => 'nested arithmetic',
        expect => {
            'foo'                       => 'executed',
            'foo > nested arithmetic'   => 'executed',
            'foo > nested string'       => 'skipped',
            'bar'                       => 'skipped',
            'baz'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with no match - skips all tests',
        filter => 'nonexistent',
        expect => {
            'foo'                       => 'skipped',
            'bar'                       => 'skipped',
            'baz'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial nested path match - skips all (single word)',
        filter => 'nested',
        expect => {
            'foo'                       => 'executed',
            'foo > nested arithmetic'   => 'executed',
            'foo > nested string'       => 'executed',
            'bar'                       => 'skipped',
            'baz'                       => 'executed',
            'baz > nested deep'         => 'executed',
            'baz > nested deep > nested very deep' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial nested path match - skips all (two words)',
        filter => 'foo nested',
        expect => {
            'foo'                       => 'executed',
            'foo > nested arithmetic'   => 'executed',
            'foo > nested string'       => 'executed',
            'bar'                       => 'skipped',
            'baz'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial match behavior - substring match works',
        filter => 'fo',
        expect => {
            'foo'                       => 'executed',
            'foo > nested arithmetic'   => 'executed',
            'foo > nested string'       => 'executed',
            'bar'                       => 'skipped',
            'baz'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with multiple patterns - foo and baz',
        filter => 'foo|baz',
        expect => {
            'foo'                       => 'executed',
            'foo > nested arithmetic'   => 'executed',
            'foo > nested string'       => 'executed',
            'bar'                       => 'skipped',
            'baz'                       => 'executed',
            'baz > nested deep'         => 'executed',
            'baz > nested deep > nested very deep' => 'executed',
        },
    },
);

for my $tc (@tests) {
    subtest $tc->{name} => sub {
        my $stdout = run_test_file($test_file, $tc->{filter});

        for my $name (sort keys %{$tc->{expect}}) {
            my $status = $tc->{expect}{$name};
            if ($status eq 'executed') {
                like($stdout, match_executed($name), "$name is executed");
            } elsif ($status eq 'skipped') {
                like($stdout, match_skipped($name), "$name is skipped");
            }
        }
    };
}

done_testing;
