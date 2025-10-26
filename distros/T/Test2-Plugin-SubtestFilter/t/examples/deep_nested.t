use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::SubtestFilter;

subtest 'level1' => sub {
    ok 1, 'level1 test';

    subtest 'level2' => sub {
        ok 1, 'level2 test';

        subtest 'level3' => sub {
            ok 1, 'level3 test';

            subtest 'level4' => sub {
                ok 1, 'level4 test';

                subtest 'level5' => sub {
                    ok 1, 'level5 test - deepest';
                };
            };
        };
    };
};

subtest 'another' => sub {
    ok 1, 'another test';

    subtest 'branch' => sub {
        ok 1, 'branch test';

        subtest 'deep' => sub {
            ok 1, 'deep test';

            subtest 'deeper' => sub {
                ok 1, 'deeper test';

                subtest 'deepest' => sub {
                    ok 1, 'deepest test';
                };
            };
        };
    };
};

done_testing;
