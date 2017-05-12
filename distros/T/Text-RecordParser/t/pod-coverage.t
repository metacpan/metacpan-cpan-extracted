#!perl

use Test::More;
eval 'use Test::Pod::Coverage 1.04';

if ( $@ ) {
    plan skip_all => 'Test::Pod::Coverage 1.04 required for POD coverage' 
}

all_pod_coverage_ok();
