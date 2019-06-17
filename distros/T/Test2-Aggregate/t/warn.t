# use Test2::Tools::Basic;
use Test2::V0;
use Test2::Aggregate;

plan(6);

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
            root => '/xx'
        )
    },
    [qr/Root .* does not exist/],
    'Single warning for invalid root.'
);
