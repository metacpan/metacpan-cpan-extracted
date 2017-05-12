# Mixing bg_subtest() and subtest() in a test script

use strict;
use warnings;

use t::MyTest;
use Test::More;

same_as_subtest subtest_before => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    ok 1, 'firsttest';

    subtest foo => sub {
        is 1, 1, "pass";
    };

    bg_subtest bar => sub {
        is 1, 1, "pass";
    };

    done_testing;
END

same_as_subtest subtest_after => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    ok 1, 'firsttest';

    bg_subtest bar => sub {
        is 1, 1, "pass";
    };

    subtest foo => sub {
        is 1, 1, "pass";
    };


    done_testing;
END

same_as_subtest nested => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    ok 1, 'firsttest';

    bg_subtest bar => sub {
        subtest innerbar => sub {
            is 1, 1, "pass";
        };
    };

    subtest foo => sub {
        bg_subtest innerfoo => sub {
            is 1, 1, "pass";
        };
    };

    bg_subtest baz => sub {
        subtest innerbaz => sub {
            is 1, 1, "pass";
        };
    };

    done_testing;
END

same_as_subtest subtest_in_parent_waits_for_kids => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    ok 1, 'firsttest';

    bg_subtest bar => sub {
        is 1, 1, "pass";
    };

    subtest foo => sub {
        ok 1, 'entering this subtest should wait for all kids...';
    };

    ok 1, '... so this test should also come after the bar results';

    done_testing;
END

same_as_subtest subtest_end_waits_for_kids => <<END;
    use Test::ParallelSubtest;
    use Test::More;

    ok 1, 'firsttest';

    subtest foo => sub {
        ok 2, 'another test';
        bg_subtest bar => sub {
            is 1, 1, "pass";
        };
    };

    ok 3, 'end of subtest foo waits for child bar, making this test last';

    done_testing;
END

done_testing;


