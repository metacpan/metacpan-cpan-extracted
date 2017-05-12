#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::Pod::Coverage; };
    my $test_pod_coverage = $@ ? 0 : 1;
    sub TEST_POD_COVERAGE {$test_pod_coverage}
}

if (TEST_POD_COVERAGE) {
    eval { Test::Pod::Coverage::all_pod_coverage_ok() };
}
else {
    plan skip_all => "Test::Pod::Coverage required";
}
