use Test2::Tools::Basic;
use Test2::Aggregate;

eval "use Time::HiRes";
plan skip_all => "Time::HiRes required for stats_output option" if $@;

plan(2);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

Test2::Aggregate::run_tests(
    dirs         => ['xt/aggregate'],
    root         => $root,
    stats_output => '/tmp/tmp.txt'
);

