use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::SubtestFilter;

# Test 1: Standard syntax with single quotes
subtest 'standard_single' => sub {
    ok 1, 'test 1';
};

# Test 2: Standard syntax with double quotes
subtest "standard_double" => sub {
    ok 1, 'test 2';
};

# Test 3: Parenthesized call with fat comma
subtest('paren_fat_comma' => sub {
    ok 1, 'test 3';
});

# Test 4: Parenthesized call with comma
subtest('paren_comma', sub {
    ok 1, 'test 4';
});

# Test 5: Fat comma without quotes (bareword)
subtest bareword => sub {
    ok 1, 'test 5';
};

# Test 6: Non-ASCII with single quotes
subtest 'あああ' => sub {
    ok 1, 'test 6';
};

# Test 7: Non-ASCII with double quotes
subtest "いいい" => sub {
    ok 1, 'test 7';
};

# Test 8: Emoji
subtest '🎉🎊' => sub {
    ok 1, 'test 8';
};

# Test 9: Nested with various syntax
subtest 'parent' => sub {
    ok 1, 'parent test';

    subtest('nested_paren' => sub {
        ok 1, 'nested test 1';
    });

    subtest nested_bareword => sub {
        ok 1, 'nested test 2';
    };

    subtest 'ネスト' => sub {
        ok 1, 'nested test 3';
    };
};

# Test 10: Mixed quotes and special chars
subtest "mixed-chars_123" => sub {
    ok 1, 'test 10';
};

# Test 11: Variable interpolation in test name
my $foo = 'bar';
subtest "foo: $foo" => sub {
    ok 1, 'test 11';
};

# Test 12: Non-ASCII bareword (Japanese hiragana)
subtest ううう => sub {
    ok 1, 'test 12';
};

# Test 13: Variable as name (filters by variable name "$var_name", not its value)
my $var_name = 'dynamic_value';
subtest $var_name => sub {
    ok 1, 'test 13 - filters by $var_name, not "dynamic_value"';
};

# Test 14: Nested with variable name
subtest 'variable_parent' => sub {
    ok 1, 'variable parent test';

    my $nested_var = 'nested_dynamic';
    subtest $nested_var => sub {
        ok 1, 'nested variable test - filters by $nested_var';
    };
};

done_testing;
