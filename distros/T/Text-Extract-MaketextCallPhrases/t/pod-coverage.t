#!perl

use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage v1.04 required for testing POD coverage' if $@;
all_pod_coverage_ok();
