use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.48";
plan skip_all => "Test::Pod 1.48 required for testing POD" if $@;
all_pod_files_ok();
