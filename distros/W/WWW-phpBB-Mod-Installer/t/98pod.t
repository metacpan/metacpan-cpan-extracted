use strict;
use warnings;
use Test::More;
plan( skip_all => 'skipping developer tests' ) unless -d ".svn";
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
