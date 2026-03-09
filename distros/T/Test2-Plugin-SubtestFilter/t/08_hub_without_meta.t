use Test2::V0;

use lib 't/lib';
use TestHelper;

my $test_file = 't/examples/hub_without_meta.t';

# When subtests are wrapped by subtest_streamed (which does not go through
# the SubtestFilter-overridden subtest), hubs without 'subtest_name' metadata
# exist in the stack. Direct regex matching still works, but index-based
# descendant matching is unreliable, so subtests with unknown hubs in their
# path run unfiltered (fail-safe) to avoid accidentally skipping tests.
#
# 'other' is a sibling of 'top' at the top level (no unknown hubs), so
# normal filtering applies and it gets correctly skipped when not matching.

my @tests = (
    {
        name => 'SUBTEST_FILTER=inner_foo - direct match works, others run via fail-safe, other is skipped',
        filter => 'inner_foo',
        expect => {
            'top'                        => 'executed', # has matching descendant in file-parsed structure
            'top > inner_foo'            => 'executed', # direct match
            'top > inner_bar'            => 'executed', # fail-safe: unknown hub in path
            'top > inner_bar > deep'     => 'executed', # fail-safe: unknown hub in path
            'other'                      => 'skipped',  # no match, no unknown hub
        },
    },
    {
        name => 'SUBTEST_FILTER=deep - direct match works, others run via fail-safe, other is skipped',
        filter => 'deep',
        expect => {
            'top'                        => 'executed', # has matching descendant in file-parsed structure
            'top > inner_foo'            => 'executed', # fail-safe: unknown hub in path
            'top > inner_bar'            => 'executed', # fail-safe: unknown hub in path
            'top > inner_bar > deep'     => 'executed', # direct match
            'other'                      => 'skipped',  # no match, no unknown hub
        },
    },
    {
        name => 'SUBTEST_FILTER=top - parent match runs all children, other is skipped',
        filter => 'top',
        expect => {
            'top'                        => 'executed', # direct match, all children run
            'top > inner_foo'            => 'executed',
            'top > inner_bar'            => 'executed',
            'top > inner_bar > deep'     => 'executed',
            'other'                      => 'skipped',  # no match
        },
    },
    {
        name => 'SUBTEST_FILTER=other - other runs, top is skipped',
        filter => '^other$',
        expect => {
            'top'   => 'skipped',  # no match, no matching descendants
            'other' => 'executed', # direct match
        },
    },
    {
        name => 'SUBTEST_FILTER=nonexistent - everything is skipped',
        filter => 'nonexistent',
        expect => {
            'top'   => 'skipped',
            'other' => 'skipped',
        },
    },
    {
        name => 'no SUBTEST_FILTER - all tests run normally',
        filter => undef,
        expect => {
            'top'                        => 'executed',
            'top > inner_foo'            => 'executed',
            'top > inner_bar'            => 'executed',
            'top > inner_bar > deep'     => 'executed',
            'other'                      => 'executed',
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
