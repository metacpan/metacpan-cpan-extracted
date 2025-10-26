use Test2::V0;

use lib 't/lib';
use TestHelper;

my $test_file = 't/examples/syntax_variations.t';
my $test_file_edge = 't/examples/edge_cases.t';

my @tests = (
    {
        name => 'no SUBTEST_FILTER - all tests run',
        filter => undef,
        expect => {
            'standard_single'       => 'executed',
            'standard_double'       => 'executed',
            'paren_fat_comma'       => 'executed',
            'paren_comma'           => 'executed',
            'bareword'              => 'executed',
            'あああ'                => 'executed',
            'いいい'                => 'executed',
            '🎉🎊'                  => 'executed',
            'parent'                => 'executed',
            'parent > nested_paren' => 'executed',
            'parent > nested_bareword' => 'executed',
            'parent > ネスト'       => 'executed',
            'mixed-chars_123'       => 'executed',
            'foo: bar'              => 'executed',
            'ううう'                => 'executed',
            'dynamic_value'         => 'executed',  # Variable $var_name resolves to this at runtime
            'variable_parent'       => 'executed',
            'variable_parent > nested_dynamic' => 'executed',  # Variable $nested_var resolves to this
        },
    },
    {
        name => 'SUBTEST_FILTER=paren - matches parenthesized calls',
        filter => 'paren',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'executed',
            'paren_comma'           => 'executed',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'executed',
            'parent > nested_paren' => 'executed',
            # When parent matches, all children are executed
            'parent > nested_bareword' => 'executed',
            'parent > ネスト'       => 'executed',
            'mixed-chars_123'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=bareword - matches bareword',
        filter => 'bareword',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'executed',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            # parent is executed because it has a matching child (nested_bareword)
            'parent'                => 'executed',
            'parent > nested_paren' => 'skipped',
            'parent > nested_bareword' => 'executed',
            'parent > ネスト'       => 'skipped',
            'mixed-chars_123'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=あああ - matches Japanese',
        filter => 'あああ',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'executed',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'skipped',
            'mixed-chars_123'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=🎉 - matches emoji',
        filter => '🎉',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'executed',
            'parent'                => 'skipped',
            'mixed-chars_123'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER="parent nested_paren" - nested with paren',
        filter => 'parent nested_paren',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'executed',
            'parent > nested_paren' => 'executed',
            'parent > nested_bareword' => 'skipped',
            'parent > ネスト'       => 'skipped',
            'mixed-chars_123'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER="parent ネスト" - nested with Japanese',
        filter => 'parent ネスト',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'executed',
            'parent > nested_paren' => 'skipped',
            'parent > nested_bareword' => 'skipped',
            'parent > ネスト'       => 'executed',
            'mixed-chars_123'       => 'skipped',
            'foo: bar'              => 'skipped',
            'ううう'                => 'skipped',
            # Note: variable-based subtests are not checked as they cannot be parsed statically
            'variable_parent'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=ううう - matches non-ASCII bareword',
        filter => 'ううう',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'skipped',
            'mixed-chars_123'       => 'skipped',
            'foo: bar'              => 'skipped',
            'ううう'                => 'executed',
            'variable_parent'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=dynamic_value - matches runtime variable value',
        filter => 'dynamic_value',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'skipped',
            'mixed-chars_123'       => 'skipped',
            'foo: bar'              => 'skipped',
            'ううう'                => 'skipped',
            # At runtime, $var_name = 'dynamic_value', so it matches
            'dynamic_value'         => 'executed',
            'variable_parent'       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=nested_dynamic - cannot match (not in parsed structure)',
        filter => 'nested_dynamic',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'skipped',
            '🎉🎊'                  => 'skipped',
            'parent'                => 'skipped',
            'mixed-chars_123'       => 'skipped',
            'foo: bar'              => 'skipped',
            'ううう'                => 'skipped',
            'dynamic_value'         => 'skipped',
            # Variable-based subtests cannot be matched via static parsing
            # They would need runtime filtering (not currently supported)
            'variable_parent'       => 'skipped',
        },
    },
    # Edge cases from edge_cases.t
    {
        name => 'SUBTEST_FILTER="test => value" - matches subtest with arrow in name',
        file => $test_file_edge,
        filter => 'test => value',
        expect => {
            'test => value' => 'executed',
            'test { block }' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER="test \\{ block \\}" - matches subtest with braces in name',
        file => $test_file_edge,
        filter => 'test \\{ block \\}',
        expect => {
            'test => value' => 'skipped',
            'test { block }' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER with very long name - handles long names correctly',
        file => $test_file_edge,
        filter => 'this_is_a_very_long',
        expect => {
            'this_is_a_very_long_subtest_name_that_tests_if_the_parser_can_handle_really_long_names_correctly' => 'executed',
        },
    },
    # Additional edge cases for syntax variations
    {
        name => 'SUBTEST_FILTER=foo1 - exact match at top level with similar siblings',
        file => $test_file_edge,
        filter => '^foo1$',
        expect => {
            'foo1'   => 'executed',
            'foo2'   => 'skipped',
            'foobar' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=foo2 - exact match selects only foo2, not foo1',
        file => $test_file_edge,
        filter => '^foo2$',
        expect => {
            'foo1'   => 'skipped',
            'foo2'   => 'executed',
            'foobar' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=mixed - verifies regular tests are ignored',
        file => $test_file_edge,
        filter => 'mixed',
        expect => {
            'foo1'   => 'skipped',
            'foo2'   => 'skipped',
            'foobar' => 'skipped',
            'mixed1' => 'executed',
            'mixed2' => 'executed',
            # Regular tests (ok 1, ...) should not interfere
        },
    },
    {
        name => 'SUBTEST_FILTER=\"test-with\" - matches dash-separated names',
        file => $test_file_edge,
        filter => 'test-with',
        expect => {
            'test-with-dashes' => 'executed',
            'test_with_underscores' => 'skipped',
            'test.with.dots' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=\"test_with\" - matches underscore-separated names',
        file => $test_file_edge,
        filter => 'test_with',
        expect => {
            'test-with-dashes' => 'skipped',
            'test_with_underscores' => 'executed',
            'test.with.dots' => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=\"root branch_a\" - selects one branch in multi-branch tree',
        file => $test_file_edge,
        filter => 'root branch_a',
        expect => {
            'root'                  => 'executed',
            'root > branch_a'       => 'executed',
            'root > branch_a > leaf' => 'executed',
            'root > branch_b'       => 'skipped',
            # branch_b > leaf is not checked because parent is skipped
        },
    },
    {
        name => 'SUBTEST_FILTER=\"standard\" - matches both single and double quoted subtests',
        file => $test_file,
        filter => 'standard',
        expect => {
            'standard_single'       => 'executed',
            'standard_double'       => 'executed',
            'paren_fat_comma'       => 'skipped',
            'paren_comma'           => 'skipped',
            'bareword'              => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=\"^mixed-chars_123$\" - exact match with special chars',
        file => $test_file,
        filter => '^mixed-chars_123$',
        expect => {
            'standard_single'       => 'skipped',
            'standard_double'       => 'skipped',
            'paren_fat_comma'       => 'skipped',
            'bareword'              => 'skipped',
            'mixed-chars_123'       => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER=\"いいい\" - matches double-quoted Japanese',
        file => $test_file,
        filter => 'いいい',
        expect => {
            'standard_single'       => 'skipped',
            'あああ'                => 'skipped',
            'いいい'                => 'executed',
            '🎉🎊'                  => 'skipped',
            'ううう'                => 'skipped',
        },
    },
);

for my $tc (@tests) {
    subtest $tc->{name} => sub {
        my $stdout = run_test_file($tc->{file} // $test_file, $tc->{filter});

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
