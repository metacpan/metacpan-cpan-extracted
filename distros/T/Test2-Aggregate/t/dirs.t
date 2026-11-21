use Test2::V0;
use Test2::Aggregate;

plan(7);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

Test2::Aggregate::run_tests();

my $stats = Test2::Aggregate::run_tests(
    dirs         => ['xt/aggregate'],
    no_dot       => 1,
    bail_on_fail => eval { require Test2::Plugin::BailOnFail; 1 },
    root         => $root
);

is(scalar(keys %$stats), 2, 'subtests');

Test2::Aggregate::run_tests(
    dirs         => ['xt/aggregate'],
    load_modules => ['Test2::V0'],
    package      => 1,
    reverse      => 1,
    root         => $root
);

Test2::Aggregate::run_tests(
    dirs          => ['xt/aggregate'],
    load_modules  => ['Test2::V0'],
    package       => 1,
    reverse       => 1,
    root          => '../',
    relative_root => 1
);
