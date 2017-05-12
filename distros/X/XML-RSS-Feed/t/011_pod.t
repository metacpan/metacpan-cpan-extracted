#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::Pod; };
    my $test_pod = $@ ? 0 : 1;
    sub TEST_POD {$test_pod}
}

if (TEST_POD) {
    eval { Test::Pod::all_pod_files_ok() };
}
else {
    plan skip_all => "Test::Pod::Coverage required";
}
