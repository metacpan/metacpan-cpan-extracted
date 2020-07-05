use Test2::V0;
use Test2::Aggregate;

plan(5);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

Test2::Aggregate::run_tests();

my $stats = Test2::Aggregate::run_tests(
    dirs => ['xt/aggregate'],
    root => $root
);

is(scalar(keys %$stats), 2, 'subtests');

Test2::Aggregate::run_tests(
    dirs         => ['xt/aggregate'],
    load_modules => ['Test2::V0'],
    package      => 1,
    reverse      => 1,
    root         => $root
);
