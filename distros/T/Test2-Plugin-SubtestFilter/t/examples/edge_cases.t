use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::SubtestFilter;

# Edge case 1: Sibling subtests with similar names at same depth
subtest 'foo1' => sub {
    ok 1, 'foo1 test';
};

subtest 'foo2' => sub {
    ok 1, 'foo2 test';
};

subtest 'foobar' => sub {
    ok 1, 'foobar test';
};

# Edge case 2: Mixed regular tests and subtests
ok 1, 'regular test 1';
ok 1, 'regular test 2';

subtest 'mixed1' => sub {
    ok 1, 'mixed1 test 1';
    ok 1, 'mixed1 test 2';
    ok 1, 'mixed1 test 3';
};

ok 1, 'regular test 3';

subtest 'mixed2' => sub {
    ok 1, 'mixed2 test';
};

# Edge case 3: Subtests with similar names at different nesting levels
subtest 'level' => sub {
    ok 1, 'level test';

    subtest 'level' => sub {
        ok 1, 'nested level test';

        subtest 'level' => sub {
            ok 1, 'deeply nested level test';
        };
    };
};

# Edge case 4: Subtests with numbers
subtest 'test_001' => sub {
    ok 1, 'test 001';
};

subtest 'test_002' => sub {
    ok 1, 'test 002';
};

subtest 'test_010' => sub {
    ok 1, 'test 010';
};

# Edge case 5: Complex nesting with multiple branches
subtest 'root' => sub {
    ok 1, 'root test';

    subtest 'branch_a' => sub {
        ok 1, 'branch_a test';

        subtest 'leaf' => sub {
            ok 1, 'branch_a leaf';
        };
    };

    subtest 'branch_b' => sub {
        ok 1, 'branch_b test';

        subtest 'leaf' => sub {
            ok 1, 'branch_b leaf';
        };
    };
};

# Edge case 6: Special characters in names
subtest 'test-with-dashes' => sub {
    ok 1, 'test with dashes';
};

subtest 'test_with_underscores' => sub {
    ok 1, 'test with underscores';
};

subtest 'test.with.dots' => sub {
    ok 1, 'test with dots';
};

# Edge case 7: Very long subtest name
subtest 'this_is_a_very_long_subtest_name_that_tests_if_the_parser_can_handle_really_long_names_correctly' => sub {
    ok 1, 'long name test';
};

# Edge case 8: Subtests that look like they might contain code
subtest 'test => value' => sub {
    ok 1, 'arrow in name';
};

subtest 'test { block }' => sub {
    ok 1, 'braces in name';
};

done_testing;
