use Test2::V0;
use Test2::Aggregate;

my $root = (grep {/^\.$/i} @INC) ? undef : './';

local $ENV{AGGREGATE_TEST_PACKAGE} = 1;

Test2::Aggregate::run_tests(
    dirs          => ['xt/aggregate'],
    package       => 1,
    repeat        => 2,
    root          => $root,
    test_warnings => 1
);

eval "use Test2::Plugin::BailOnFail";
unless ($@) {

    # Careful, repeat -1 loads bail on fail, has to be last
    like(
        warning {
            Test2::Aggregate::run_tests(
                dirs          => ['xt/aggregate'],
                repeat        => -1,
                root          => $root,
                test_warnings => 1
            );
        },
        qr'Subroutine test_package redefined',
        "Got expected redefine warning"
    );
}

done_testing;