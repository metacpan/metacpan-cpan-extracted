#!/usr/bin/perl 
use Test::More;
use strict;
use warnings;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my $trustparents = { coverage_class => qw(Pod::Coverage::CountParents) };
all_pod_coverage_ok($trustparents);
