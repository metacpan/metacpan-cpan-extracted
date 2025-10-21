use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::SubtestFilter;

subtest 'foo' => sub {
    ok 1, 'foo test 1';
    ok 1, 'foo test 2';

    subtest 'nested arithmetic' => sub {
        ok 1, 'arithmetic test 1';
        ok 1, 'arithmetic test 2';
    };

    subtest 'nested string' => sub {
        ok 1, 'string test 1';
        ok 1, 'string test 2';
    };
};

subtest 'bar' => sub {
    ok 1, 'bar test 1';
    ok 1, 'bar test 2';
};

subtest 'baz' => sub {
    ok 1, 'baz test 1';

    subtest 'nested deep' => sub {
        ok 1, 'deep test 1';

        subtest 'nested very deep' => sub {
            ok 1, 'very deep test 1';
        };
    };
};

done_testing;
