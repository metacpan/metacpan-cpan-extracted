# -*- perl -*-
# check that all functions/methods are documented

use warnings;
use strict;
use Test::More;

plan skip_all => 'only run for author tests' unless $ENV{AUTHOR_TEST};
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

my @modules = all_modules('lib');
plan tests => scalar @modules;
for (@modules) { pod_coverage_ok($_); }
