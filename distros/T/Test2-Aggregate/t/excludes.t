use Test2::V0;
use Test2::Aggregate;

plan(6);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

my $run = Test2::Aggregate::run_tests(
    lists => ['xt/aggregate/aggregate.lst'],
    root  => $root
);

is(keys %$run, 2, '2 tests run');

$run = Test2::Aggregate::run_tests(
    lists    => ['xt/aggregate/aggregate.lst'],
    excludes => ['env'],
    root     => $root
);

is(keys %$run, 1, '1 test run');

$run = Test2::Aggregate::run_tests(
    lists    => ['xt/aggregate/aggregate.lst'],
    excludes => ['check'],
    root     => $root
);

is(keys %$run, 0, '0 tests to run');
