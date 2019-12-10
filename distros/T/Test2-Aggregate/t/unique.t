use Test2::V0;
use Test2::Aggregate;

my $root = (grep {/^\.$/i} @INC) ? undef : './';

my $run = Test2::Aggregate::run_tests(
    dirs          => ['xt/aggregate'],
    lists         => ['xt/aggregate/aggregate.lst'],
    root          => $root,
    test_warnings => 1
);

check_output($run, 1);

$run = Test2::Aggregate::run_tests(
    dirs          => ['xt/aggregate'],
    lists         => ['xt/aggregate/aggregate.lst'],
    root          => $root,
    unique        => 0,
    test_warnings => 1
);

check_output($run, 0);

done_testing;

sub check_output {
    my $run  = shift;
    my $uniq = shift;
    my $r    = $root || '';
    my $pass = $uniq ? 100 : 200;

    is(
        $run,
        {
            $r.'xt/aggregate/check_env.t' => {
                'timestamp' => E(),
                'pass_perc' => $pass,
                'test_no'   => T(),
            },
            $r.'xt/aggregate/check_plan.t' => {
                'test_no'   => T(),
                'timestamp' => E(),
                'pass_perc' => $pass
            }
        },
        "Correct output - uniq = $uniq"
    );
}
