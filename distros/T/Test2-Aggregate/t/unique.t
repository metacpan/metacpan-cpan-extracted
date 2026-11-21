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
    bail_on_fail  => eval { require Test2::Plugin::BailOnFail; 1 },
    test_warnings => 1
);

check_output($run, 0);

done_testing;

sub check_output {
    my $run  = shift;
    my $uniq = shift;
    my $pass = $uniq ? 100 : 200;

    is(
        $run,
        {
            'xt/aggregate/check_env.t' => {
                'timestamp' => E(),
                'pass_perc' => $pass,
                'test_no'   => T(),
            },
            'xt/aggregate/check_plan.t' => {
                'test_no'   => T(),
                'timestamp' => E(),
                'pass_perc' => $pass
            }
        },
        "Correct output - uniq = $uniq"
    );
}
