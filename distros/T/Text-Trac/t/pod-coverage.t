#!perl -T
use strict;
use warnings;

use Test::More;
## no critic
eval 'use Test::Pod::Coverage 1.04 tests=>1';
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' if $@;
pod_coverage_ok( 'Text::Trac', 'Text::Trac is covered' );
