use Test2::V0;
use Test2::Aggregate;

eval "use Test2::Plugin::BailOnFail";
plan skip_all => "Test2::Plugin::BailOnFail required for the repeat < 0 option" if $@;

plan(1);

my $root = (grep {/^\.$/i} @INC) ? undef : './';

local $ENV{AGGREGATE_TEST_FAIL} = 1;

like(
    intercept {
        Test2::Aggregate::run_tests(
            dirs   => ['xt/aggregate'],
            repeat => -1,
            root   => $root
            )
    },
    array {
        filter_items {
            grep {$_->isa('Test2::Event::Bail')} @_
        };
        event Bail => {reason => "(Bail On Fail)"};
        end;
    }
    ,
    'Bailed after test failure'
);

