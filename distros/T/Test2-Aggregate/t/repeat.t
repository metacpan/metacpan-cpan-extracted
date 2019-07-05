use Test2::Tools::Basic;
use Test2::Aggregate;

plan(4);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

Test2::Aggregate::run_tests(
    dirs   => ['xt/aggregate'],
    root   => $root,
    repeat => 2
);
