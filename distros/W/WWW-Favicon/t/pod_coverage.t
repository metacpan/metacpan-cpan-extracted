use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Set TEST_POD environment variable to run this test"
    unless $ENV{TEST_POD};
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
all_pod_coverage_ok();
