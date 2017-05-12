# Testing use of Test::ParallelSubtest without actually using bg_subtest.

use strict;
use warnings;

use t::MyTest;
use Test::More;

same_as_subtest donothing => <<END;
    use Test::ParallelSubtest;
END

same_as_subtest overplan => <<END;
    use Test::ParallelSubtest;
    use Test::More tests => 1;
END

same_as_subtest onetest_pass => <<END;
    use Test::ParallelSubtest;
    use Test::More tests => 1;

    is 1, 1, 'foo';
END

same_as_subtest onetest_fail => <<END;
    use Test::ParallelSubtest;
    use Test::More tests => 1;

    is 0, 1, 'foo';
END

same_as_subtest onetest_pass_noplan => <<END;
    use Test::ParallelSubtest;
    use Test::More 'no_plan';

    is 1, 1, 'foo';
END

same_as_subtest onetest_fail_noplan => <<END;
    use Test::ParallelSubtest;
    use Test::More 'no_plan';

    is 0, 1, 'foo';
END

same_as_subtest onetest_pass_dt => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    is 1, 1, 'foo';
    done_testing;
END

same_as_subtest onetest_fail_dt => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    is 0, 1, 'foo';
    done_testing;
END

same_as_subtest xmas => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    is 1, 1, "pass";
    is 1, 0, "fail";

    subtest foo => sub {
        is 1, 1, "pass";
        is 1, 0, "fail";
        subtest bar => sub {
            is 1, 1, "pass";
            is 1, 0, "fail";
            warn "warning from deep in a subtest\n";
        };
    };

    ok 1, 'yes';
    warn "this is a warning\n";
    ok 1, 'yes';
    ok 0, 'no';

    done_testing;
END

done_testing;


