use Test2::V0;
use Test2::Aggregate;

plan(10);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

my $run = Test2::Aggregate::run_tests(
    lists => ['xt/aggregate/aggregate.lst'],
    root  => $root
);

is(keys %$run, 2, '2 tests run');

$run = Test2::Aggregate::run_tests(
    lists   => ['xt/aggregate/aggregate.lst'],
    exclude => qr/env/,
    root    => $root
);

is(keys %$run, 1, '1 test run');

$run = Test2::Aggregate::run_tests(
    lists   => ['xt/aggregate/aggregate.lst'],
    exclude => qr/check/,
    root    => $root
);

is(keys %$run, 0, '0 tests to run');

$run = Test2::Aggregate::run_tests(
    lists   => ['xt/aggregate/aggregate.lst'],
    include => qr/env/,
    root    => $root
);

is(keys %$run, 1, '1 tests to run');

$run = Test2::Aggregate::run_tests(
    lists   => ['xt/aggregate/aggregate.lst'],
    exclude => qr/env/,
    include => qr/env/,
    root    => $root
);

is(keys %$run, 0, '1 tests to run');

$run = Test2::Aggregate::run_tests(
    lists   => ['xt/aggregate/aggregate.lst'],
    include => qr/\d/,
    root    => $root
);

is(keys %$run, 0, '0 tests to run');
