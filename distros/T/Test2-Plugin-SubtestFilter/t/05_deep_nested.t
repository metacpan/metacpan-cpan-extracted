use Test2::V0;

use lib 't/lib';
use TestHelper;

my $test_file_deep = 't/examples/deep_nested.t';
my $test_file_basic = 't/examples/basic.t';
my $test_file_edge = 't/examples/edge_cases.t';

my @tests = (
    {
        name => 'SUBTEST_FILTER for 5-level deep path - full path match',
        file => $test_file_deep,
        filter => 'level1 level2 level3 level4 level5',
        expect => {
            'level1'                                => 'executed',
            'level1 > level2'                       => 'executed',
            'level1 > level2 > level3'              => 'executed',
            'level1 > level2 > level3 > level4'     => 'executed',
            'level1 > level2 > level3 > level4 > level5' => 'executed',
            'another' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER for deeply nested baz path - basic.t',
        file => $test_file_basic,
        filter => 'baz nested deep nested very deep',
        expect => {
            'foo'  => 'skipped',
            'bar'  => 'skipped',
            'baz'  => 'executed',
            'baz > nested deep' => 'executed',
            'baz > nested deep > nested very deep' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER for another branch deep path',
        file => $test_file_deep,
        filter => 'another branch deep deeper deepest',
        expect => {
            'level1'   => 'skipped',
            'another'  => 'executed',
            'another > branch' => 'executed',
            'another > branch > deep' => 'executed',
            'another > branch > deep > deeper' => 'executed',
            'another > branch > deep > deeper > deepest' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial deep match - level5',
        file => $test_file_deep,
        filter => 'level5',
        expect => {
            'level1'  => 'executed',
            'level1 > level2' => 'executed',
            'level1 > level2 > level3' => 'executed',
            'level1 > level2 > level3 > level4' => 'executed',
            'level1 > level2 > level3 > level4 > level5' => 'executed',
            'another' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial deep match - deepest',
        file => $test_file_deep,
        filter => 'deepest',
        expect => {
            'level1'   => 'skipped',
            'another'  => 'executed',
            'another > branch' => 'executed',
            'another > branch > deep' => 'executed',
            'another > branch > deep > deeper' => 'executed',
            'another > branch > deep > deeper > deepest' => 'executed',
        },
    },
    # Edge cases
    {
        name => 'SUBTEST_FILTER=foo1 - matches only foo1, not foo2 or foobar',
        file => $test_file_edge,
        filter => '^foo1$',
        expect => {
            'foo1'   => 'executed',
            'foo2'   => 'skipped',
            'foobar' => 'skipped',
            'mixed1' => 'skipped',
            'mixed2' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=foo - matches all foo* subtests',
        file => $test_file_edge,
        filter => 'foo',
        expect => {
            'foo1'   => 'executed',
            'foo2'   => 'executed',
            'foobar' => 'executed',
            'mixed1' => 'skipped',
            'mixed2' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=mixed - regular tests are ignored, only subtests match',
        file => $test_file_edge,
        filter => 'mixed',
        expect => {
            'foo1'   => 'skipped',
            'foo2'   => 'skipped',
            'foobar' => 'skipped',
            'mixed1' => 'executed',
            'mixed2' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER="level level level" - matches nested subtests with same name',
        file => $test_file_edge,
        filter => 'level level level',
        expect => {
            'level'         => 'executed',
            'level > level' => 'executed',
            'level > level > level' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER="root branch_a leaf" - matches one branch, not the other',
        file => $test_file_edge,
        filter => 'root branch_a leaf',
        expect => {
            'root'                  => 'executed',
            'root > branch_a'       => 'executed',
            'root > branch_a > leaf' => 'executed',
            'root > branch_b'       => 'skipped',
            # branch_b > leaf is not checked because parent is skipped
        },
    },
    {
        name => 'SUBTEST_FILTER="root branch_b leaf" - matches the other branch',
        file => $test_file_edge,
        filter => 'root branch_b leaf',
        expect => {
            'root'                  => 'executed',
            'root > branch_a'       => 'skipped',
            # branch_a > leaf is not checked because parent is skipped
            'root > branch_b'       => 'executed',
            'root > branch_b > leaf' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER=leaf - matches both leaf nodes',
        file => $test_file_edge,
        filter => 'leaf',
        expect => {
            'root'                  => 'executed',
            'root > branch_a'       => 'executed',
            'root > branch_a > leaf' => 'executed',
            'root > branch_b'       => 'executed',
            'root > branch_b > leaf' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER=test_001 - exact match with numbers',
        file => $test_file_edge,
        filter => 'test_001',
        expect => {
            'test_001' => 'executed',
            'test_002' => 'skipped',
            'test_010' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER="test_00" - partial match with numbers',
        file => $test_file_edge,
        filter => 'test_00',
        expect => {
            'test_001' => 'executed',
            'test_002' => 'executed',
            'test_010' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER="test-with" - matches special characters (dash)',
        file => $test_file_edge,
        filter => 'test-with',
        expect => {
            'test-with-dashes' => 'executed',
            'test_with_underscores' => 'skipped',
            'test.with.dots' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER="test.with" - matches special characters (dot)',
        file => $test_file_edge,
        filter => 'test\\.with',
        expect => {
            'test-with-dashes' => 'skipped',
            'test_with_underscores' => 'skipped',
            'test.with.dots' => 'executed',
        },
    },
);

for my $tc (@tests) {
    subtest $tc->{name} => sub {
        my $stdout = run_test_file($tc->{file}, $tc->{filter});

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
