#!/usr/bin/perl

use Test::More;
plan skip_all => 'Author test.  Set $ENV{ TEST_AUTHOR } to enable this test.' unless $ENV{ TEST_AUTHOR };
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
