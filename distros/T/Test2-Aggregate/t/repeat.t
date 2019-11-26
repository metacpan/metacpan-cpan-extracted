use Test2::V0;
use Test2::Aggregate;

plan(5);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

Test2::Aggregate::run_tests(
    dirs   => ['xt/aggregate'],
    root   => $root,
    repeat => 2
);

local $ENV{AGGREGATE_TEST_FAIL} = 1;

my $run;

intercept {
    $run = Test2::Aggregate::run_tests(
        dirs   => ['xt/aggregate'],
        sort   => 1,
        repeat => 2,
        root   => $root
        )
};

like(
    $run,
    {
        'xt/aggregate/check_env.t' => {
            'timestamp' => E(),
            'pass_perc' => 0,
            'test_no'   => 1
        },
        'xt/aggregate/check_plan.t' => {
            'test_no'   => 2,
            'timestamp' => E(),
            'pass_perc' => 100
        }
    },
    "Correct output including failure."
);
