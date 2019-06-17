use Test2::Tools::Basic;
use Test2::Aggregate;

eval "use Sub::Override";
plan skip_all => "Sub::Override required for override option" if $@;

plan(1);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

Test2::Aggregate::run_tests(
    dirs     => ['xt/aggregate'],
    root     => $root,
    override => { 'Test2::Aggregate::_run_tests' => sub { ok 1, "$0 replacement test"} }
);

