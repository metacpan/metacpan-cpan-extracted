use Test2::V0;
use Test2::Aggregate;

plan(4);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

Test2::Aggregate::run_tests(
    lists => ['xt/aggregate/aggregate.lst'],
    root  => $root
);

Test2::Aggregate::run_tests(
    lists        => ['xt/aggregate/aggregate.lst'],
    allow_errors => 1,
    root         => $root
);
