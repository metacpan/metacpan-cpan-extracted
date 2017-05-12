use Test::More;
eval "use Test::Pod";
plan skip_all => "Test::Pod required for testing pod: $@" if $@;
all_pod_files_ok();
