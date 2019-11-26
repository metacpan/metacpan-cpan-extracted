use Test2::V0;
use Test2::Aggregate;

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

intercept {
    $run = Test2::Aggregate::run_tests(
        dirs          => ['xt/aggregate'],
        repeat        => 2,
        sort          => 1,
        root          => $root,
        test_warnings => 1
    );
};

check_output($run);

eval "use Test2::Plugin::BailOnFail";

unless ($@) {
    is(
        warning {
            $run = Test2::Aggregate::run_tests(
                dirs          => ['xt/aggregate'],
                repeat        => -1,
                sort          => 1,
                root          => $root,
                test_warnings => 1
            );
        },
        "Test warning output:\n<xt/aggregate/check_env.t>\nAGGREGATE_TEST_WARN\n",
        "Got expected warning"
    );
    check_output($run);
}

done_testing;

sub check_output {
    my $run = shift;

    is(
        $run,
        {
            'xt/aggregate/check_env.t' => {
                'timestamp' => E(),
                'pass_perc' => 0,
                'warnings'  =>  'AGGREGATE_TEST_WARN',
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
}

