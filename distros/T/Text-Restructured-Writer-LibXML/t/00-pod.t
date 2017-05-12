use Test::More;
plan skip_all => 'Set DEVEL_TESTS to run these tests'
     unless $ENV{DEVEL_TESTS};
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD"
	if $@;
all_pod_files_ok();
