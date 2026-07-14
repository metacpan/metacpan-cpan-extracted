#!perl
use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval {
    require Test::Pod::Coverage;
    die
        if Test::Pod::Coverage->VERSION < $min_tpc;
    Test::Pod::Coverage->import()
};
plan skip_all
=> "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval {
    require Pod::Coverage;
    die
        if Pod::Coverage->VERSION < $min_pc;
    Pod::Coverage->import();
};

plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

all_pod_coverage_ok();
