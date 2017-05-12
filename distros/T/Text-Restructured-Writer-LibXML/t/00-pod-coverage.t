use Test::More;
plan skip_all => 'Set DEVEL_TESTS to run these tests'
     unless $ENV{DEVEL_TESTS};
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
	if $@;
all_pod_coverage_ok();
