use Test2::V0;
use Test2::Aggregate;

plan(6);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

my $run = Test2::Aggregate::run_tests(
    dirs   => ['xt/aggregate'],
    root   => $root,
    repeat => 2
);

check_output($run);

local $ENV{AGGREGATE_TEST_FAIL} = 1;

intercept {
    $run = Test2::Aggregate::run_tests(
        dirs   => ['xt/aggregate'],
        repeat => 2,
        root   => $root
    )
};

check_output($run);

sub check_output {
    my $run  = shift;
    my $r    = $root || '';
    my $pass = $ENV{AGGREGATE_TEST_FAIL} ? 0 : 100;

    like(
        $run,
        {
            $r.'xt/aggregate/check_env.t' => {
                'timestamp' => E(),
                'pass_perc' => $pass,
                'test_no'   => T()
            },
            $r.'xt/aggregate/check_plan.t' => {
                'test_no'   => T(),
                'timestamp' => E(),
                'pass_perc' => 100
            }
        },
        "Correct output - pass $pass%."
    );
}


