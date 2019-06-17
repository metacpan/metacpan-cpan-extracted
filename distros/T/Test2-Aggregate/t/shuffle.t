use Test2::Tools::Basic;
use Test2::Aggregate;

eval "use List::Util";
plan skip_all => "List::Util required for shuffle option" if $@;

plan(2);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

Test2::Aggregate::run_tests(
    dirs    => ['xt/aggregate'],
    root    => $root,
    shuffle => 1
);