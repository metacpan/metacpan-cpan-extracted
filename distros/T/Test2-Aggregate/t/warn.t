use Test2::V0;
use Test2::Aggregate;

plan(11);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

Test2::Aggregate::run_tests(
    dirs          => ['xt/aggregate'],
    lists         => ['xt/aggregate/aggregate.lst'],
    root          => $root,
    test_warnings => 1
);

like(
    warnings {
        Test2::Aggregate::run_tests(
            dirs => ['xt/aggregate'],
            root => '/xx',
            slow => 1
        );
        Test2::Aggregate::run_tests(
            dirs => ['xt/aggregate'],
            root => '/xx/',
        );
    },
    [qr/Root .* does not exist/],
    'Single warning for invalid root.'
);

local $ENV{AGGREGATE_TEST_WARN} = 1;
my $run;
is(
    warning {
        $run = Test2::Aggregate::run_tests(
    dirs          => ['xt/aggregate'],
    repeat        => -1,
    root          => $root,
    test_warnings => 1
);
    },
    'Test warning output:
<xt/aggregate/check_env.t>
AGGREGATE_TEST_WARN
',
    "Got expected warning"
);



check_output($run);

intercept {
    $run = Test2::Aggregate::run_tests(
        dirs          => ['xt/aggregate'],
        repeat        => 2,
        root          => $root,
        test_warnings => 1
    );
};

check_output($run);

sub check_output {
    my $run = shift;

    is(
        $run,
        {
            'xt/aggregate/check_plan.t' => {
                'test_no'   => 1,
                'timestamp' => E(),
                'pass_perc' => 100
            },
            'xt/aggregate/check_env.t' => {
                'timestamp' => E(),
                'pass_perc' => 0,
                'warnings'  =>  'AGGREGATE_TEST_WARN',
                'test_no'   => 2
            }
        },
        "Correct output including failure."
    );
}
