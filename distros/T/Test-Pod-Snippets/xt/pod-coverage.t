#!perl -T

use Test::More;

eval q{ use Test::Pod::Coverage; 1 }
    or plan skip_all => 'Test::Pod::Coverage not installed';

all_pod_coverage_ok();
