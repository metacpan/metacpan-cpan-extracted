use strict;
use warnings;
use Test::More;
plan( skip_all => 'skipping developer tests' ) unless -d ".svn";
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok();
