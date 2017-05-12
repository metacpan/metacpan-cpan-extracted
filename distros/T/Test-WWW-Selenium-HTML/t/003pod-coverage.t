# $Id$

use strict;
use warnings;

use blib;

use Test::More;
eval {
    require Test::Pod::Coverage;
    Test::Pod::Coverage->import();
};
plan skip_all => 
    "Test::Pod::Coverage required for testing POD coverage" if $@;

all_pod_coverage_ok();
