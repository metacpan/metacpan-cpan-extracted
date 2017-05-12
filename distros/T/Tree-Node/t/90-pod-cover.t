#!/usr/bin/perl

use strict;
use Test::More;

plan skip_all => "Enable DEVEL_TESTS environent variable"
  unless ($ENV{DEVEL_TESTS});

eval "use Test::Pod::Coverage";

plan skip_all => "Test::Pod::Coverage required" if $@;

my %MODULES = (
  'Tree::Node' => 0,
);

plan tests => scalar(keys %MODULES);

foreach my $module (sort keys %MODULES) {
  pod_coverage_ok($module);
}

