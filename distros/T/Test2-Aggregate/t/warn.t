use Test2::V0;
use Test2::Aggregate;

my $root = (grep {/^\.$/i} @INC) ? undef : './';

foreach my $abs (0..1) {
    my $run = Test2::Aggregate::run_tests(
        dirs          => ['xt/aggregate'],
        lists         => ['xt/aggregate/aggregate.lst'],
        root          => './',
        sort          => 1,
        absolute      => $abs,
        test_warnings => 1
    );

    check_output($run, $abs, "No warning", './');

}

like(
    warnings {
        Test2::Aggregate::run_tests(
            dirs     => ['xt/aggregate'],
            root     => $root,
            pre_eval => 'warn "pre_eval warn"'
        );
    },
    [qr/pre_eval warn/],
    'Warning sent with pre_eval.'
);

like(
    warnings {
        Test2::Aggregate::run_tests(
            dirs => ['xt/aggregate'],
            root => '/xx',
            slow => 1
        );
        Test2::Aggregate::run_tests(
            dirs          => ['xt/aggregate'],
            root          => '/xx/',
            relative_root => 1
        );
    },
    [qr/Root .* does not exist/],
    'Single warning for invalid root.'
);

local $ENV{AGGREGATE_TEST_WARN} = 1;

my $run;
foreach my $abs (0..1) {
    intercept {
        $run = Test2::Aggregate::run_tests(
            dirs          => ['xt/aggregate'],
            repeat        => 2,
            sort          => 1,
            root          => $root,
            absolute      => $abs,
            test_warnings => 1
        );
    };

    check_output($run, $abs, "including failure");
}

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
        match(qr#Test warning output:\n<.*check_env.t>\nAGGREGATE_TEST_WARN\nAGGREGATE_TEST_WARNx2\n#),
        "Got expected warning"
    );
    check_output($run, 0, "including failure on repeat == -1");
}

done_testing;

sub check_output {
    my $run  = shift;
    my $abs  = shift || 0;
    my $msg  = shift;
    my $r    = shift || $root || '';
    my %warn = ();
    my $pass = $ENV{AGGREGATE_TEST_WARN} ? 0 : 100;
    $warn{warnings} = "AGGREGATE_TEST_WARN\nAGGREGATE_TEST_WARNx2\n"
        if $ENV{AGGREGATE_TEST_WARN};

    $r = '' unless $abs;

    is(
        $run,
        {
            $r.'xt/aggregate/check_env.t' => {
                'timestamp' => E(),
                'pass_perc' => $pass,
                'test_no'   => 1,
                %warn
            },
            $r.'xt/aggregate/check_plan.t' => {
                'test_no'   => 2,
                'timestamp' => E(),
                'pass_perc' => 100
            }
        },
        "Correct output - abs:$abs $msg"
    );
}
