use Test2::Tools::Basic;
use Test2::V0;
use Test2::Aggregate;

local $ENV{SKIP_SLOW} = 1;

is(
    warnings {
        Test2::Aggregate::run_tests(
            dirs => ['xt/aggregate'],
            root => '/xx',
            slow => 1
        )
    },
    [],
    'No warning, test skipped.'
);

done_testing;