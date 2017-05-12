# Basic usage

use strict;
use warnings;

use t::MyTest;
use Test::More;

same_as_subtest one_test_useplan => <<END;
    use Test::More tests => 1;
    use Test::ParallelSubtest;

    bg_subtest one => sub {
        ok 1;
        ok 0;
        done_testing;
    };
END

same_as_subtest one_test_noplan => <<END;
    use Test::More 'no_plan';
    use Test::ParallelSubtest;

    bg_subtest one => sub {
        ok 1;
        ok 0;
        done_testing;
    };
END

same_as_subtest one_test_donetesting => <<END;
    use Test::More;
    use Test::ParallelSubtest;

    bg_subtest one => sub {
        ok 1;
        ok 0;
        done_testing;
    };

    done_testing;
END

same_as_subtest one_test_missingplan => <<END;
    use Test::More;
    use Test::ParallelSubtest;

    bg_subtest one => sub {
        ok 1;
        ok 0;
        done_testing;
    };
END

same_as_subtest one_test_runtimeplan => <<END;
    use Test::More;
    use Test::ParallelSubtest;

    plan tests => 1;

    bg_subtest one => sub {
        ok 1;
        ok 0;
        done_testing;
    };
END

same_as_subtest one_test_badplan => <<END;
    use Test::More;
    use Test::ParallelSubtest;

    plan tests => 17;

    bg_subtest one => sub {
        ok 1;
        ok 0;
        done_testing;
    };
END

same_as_subtest 'subtest in bg_subtest' => <<END;
    use Test::More tests => 1;
    use Test::ParallelSubtest;

    bg_subtest one => sub {
        ok 1;
        ok 0;
        subtest foo => sub { plan tests => 1; ok 0, "fail in inner" };
        subtest bar => sub { plan tests => 1; ok 1, "pass in inner" };
        done_testing;
    };
END

same_as_subtest 'bg_subtest in subtest' => <<END;
    use Test::More tests => 1;
    use Test::ParallelSubtest;

    subtest outer => sub {
        plan tests => 2;
        bg_subtest one => sub {
            plan tests => 2;
            ok 1;
            ok 0;
        };
        bg_subtest two => sub {
            ok 1, 'second bgsubtest ok';
            done_testing;
        };
    };
END

same_as_subtest 'passing bg_subtest after failed test' => <<END;
    use Test::More tests => 2;
    use Test::ParallelSubtest;

    ok 0, 'fail';

    subtest foo => sub {
        plan tests => 1;
        ok 1, 'pass';
    };
END

done_testing;
