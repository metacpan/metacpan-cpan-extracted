use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.10";
plan skip_all => "Test::Pod::Coverage 1.10 required for testing POD coverage" if $@;
all_pod_coverage_ok();
