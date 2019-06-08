use Test2::Tools::Basic;
use Test2::Aggregate;

plan(2);

Test2::Aggregate::run_tests(
    lists => ['xt/aggregate/aggregate.lst']
);
