#!perl -T

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
plan skip_all => "Test::Pod test only run by author" if !$ENV{AUTHOR_TEST};
all_pod_files_ok();
