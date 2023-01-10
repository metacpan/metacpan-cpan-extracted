use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => 'Test::Pod::Coverage is not installed' if $@;

all_pod_coverage_ok();
