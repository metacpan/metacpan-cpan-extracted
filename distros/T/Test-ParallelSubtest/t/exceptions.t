# Exceptions and other error conditions.

use strict;
use warnings;

use t::MyTest;
use Test::More;

same_as_subtest no_plan_no_tests => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 1;

    bg_subtest foo => sub { };
END

same_as_subtest no_tests_done_testing => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 1;

    bg_subtest foo => sub { done_testing };
END

same_as_subtest no_tests_no_plan_todo => <<'END';
    use Test::ParallelSubtest;
    use Test::More;

    TODO: {
        bg_subtest foo => sub { };
    };

    done_testing;
END

same_as_subtest no_tests_done_testing_todo => <<'END';
    use Test::ParallelSubtest;
    use Test::More;

    TODO: {
        bg_subtest foo => sub { done_testing };
    };

    done_testing;
END

same_as_subtest test_after_donetesting => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 1;

    bg_subtest foo => sub {
        ok 1, 'ok';
        done_testing;
        ok 1, 'late test';
    };
END

{
    my $result = ext_perl_run <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 2;

    bg_subtest testfoo => sub {
        ok 1, 'ok';
        die "Oops!";
    };

    bg_subtest testbar => sub {
        ok 1, 'ok';
        done_testing;
    };

    done_testing;
END

    ok $result->{Status}, "die in bg_subtest makes test script fail";

    like $result->{Stdout},
        qr/not ok \d+ - failed child process for 'testfoo'/,
        "failed test output";

    like $result->{Stderr}, qr/Lost contact with the child process/,
                                                   "failure type reported";
    like $result->{Stderr}, qr/"testfoo" \(- line 7\)/,
                                    "correct subtest identified in stderr";
    like $result->{Stderr}, qr/Oops!/, "die message gets into stderr";
}

{
    my $result = ext_perl_run <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 2;

    bg_subtest testfoo => sub {
        ok 1, 'ok';
        exit 0;
    };

    bg_subtest testbar => sub {
        plan tests => 1;
        ok 1, 'ok';
    };

    done_testing;
END

    ok $result->{Status}, "exit in bg_subtest makes test script fail";

    like $result->{Stdout},
        qr/not ok \d+ - failed child process for 'testfoo'/,
        "failed test output";

    like $result->{Stderr}, qr/Lost contact with the child process/,
                                                   "failure type reported";
    like $result->{Stderr}, qr/"testfoo" \(- line 7\)/,
                                    "correct subtest identified in stderr";
}

done_testing;
