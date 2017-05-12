# Using bg_subtest_wait() to sync up output between parent and child tests.

use strict;
use warnings;

use t::MyTest;
use Test::More;

same_as_subtest simple_sync => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 2;

    bg_subtest foo => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest_wait;

    is 1, 1, '1 is 1';
END

same_as_subtest sync_2_bgtests => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 2;

    bg_subtest foo => sub {
        sleep 1;
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest bar => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest_wait;

    is 1, 1, '1 is 1';
END

done_testing;
