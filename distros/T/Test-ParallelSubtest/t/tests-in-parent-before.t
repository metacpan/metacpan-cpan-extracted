# Running tests in the parent before calling bg_subtest.  This should not mess
# up test order so long as all parent tests are done with before the first
# bg_subtest call.

use strict;
use warnings;

use t::MyTest;
use Test::More;

same_as_subtest one_bg_subtest => <<END;
    use Test::ParallelSubtest;
    use Test::More tests => 3;

    is 1, 1, '1 is 1';
    subtest foo => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest bar => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };
END

same_as_subtest two_bg_subtests => <<END;
    use Test::ParallelSubtest;
    use Test::More tests => 4;

    is 1, 1, '1 is 1';
    subtest foo => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest bar => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest baz => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };
END

same_as_subtest no_plan => <<END;
    use Test::ParallelSubtest;
    use Test::More 'no_plan';

    is 1, 1, '1 is 1';
    subtest foo => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest bar => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest baz => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };
END

same_as_subtest bad_plan => <<END;
    use Test::ParallelSubtest;
    use Test::More tests => 17;

    is 1, 1, '1 is 1';
    subtest foo => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest bar => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest baz => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };
END

same_as_subtest missing_plan => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    is 1, 1, '1 is 1';
    subtest foo => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest bar => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
        done_testing;
    };

    bg_subtest baz => sub {
        plan tests => 2;
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };
END

same_as_subtest done_testing => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    is 1, 1, '1 is 1';
    subtest foo => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
        done_testing;
    };

    bg_subtest bar => sub {
        plan tests => 2;
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest baz => sub {
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
        done_testing;
    };

    done_testing;
END

same_as_subtest tests_after_done_testing => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    is 1, 1, '1 is 1';
    subtest foo => sub {
        is 2, 2, '2 is 2';
        done_testing;
        is 3, 4, '3 is 4';
    };

    bg_subtest bar => sub {
        plan tests => 2;
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest baz => sub {
        is 2, 2, '2 is 2';
        done_testing;
        is 3, 4, '3 is 4';
    };

    done_testing;

    is 2, 3, "late test";
END

same_as_subtest subtest_after_done_testing => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    is 1, 1, '1 is 1';
    subtest foo => sub {
        is 2, 2, '2 is 2';
        done_testing;
        is 3, 4, '3 is 4';
    };

    bg_subtest bar => sub {
        plan tests => 2;
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest baz => sub {
        is 2, 2, '2 is 2';
        done_testing;
        is 3, 4, '3 is 4';
    };

    done_testing;

    subtest "late subtest" => sub {
        is 2, 3, "late test";
    };
END

same_as_subtest bg_subtest_after_done_testing => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    is 1, 1, '1 is 1';
    subtest foo => sub {
        is 2, 2, '2 is 2';
        done_testing;
        is 3, 4, '3 is 4';
    };

    bg_subtest bar => sub {
        plan tests => 2;
        is 2, 2, '2 is 2';
        is 3, 4, '3 is 4';
    };

    bg_subtest baz => sub {
        is 2, 2, '2 is 2';
        done_testing;
        is 3, 4, '3 is 4';
    };

    done_testing;

    bg_subtest "late subtest" => sub {
        is 2, 3, "late test";
    };
END

done_testing;
