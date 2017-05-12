#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

if ( not $ENV{TEST_POD} ) {
    my $msg = 'Test::Pod::Coverage test.  Set $ENV{TEST_POD} to a true value to run.';
    plan( skip_all => $msg );
}

my @modules = all_modules();

plan tests => scalar @modules;

# General modules
foreach my $module (@modules) {
	pod_coverage_ok($module);
}

done_testing();
