use Test2::Tools::Basic;
use Test2::Aggregate;

plan(2);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

Test2::Aggregate::run_tests(
    lists => ['xt/aggregate/aggregate.lst'],
    root  => $root
);
