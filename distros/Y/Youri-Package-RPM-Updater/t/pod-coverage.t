#!/usr/bin/perl
# $Id: pod-coverage.t 2318 2011-01-22 12:59:02Z guillomovitch $

use strict;
use warnings;
use Test::More;

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    unless $ENV{TEST_AUTHOR};

eval "use Test::Pod::Coverage 1.04";
plan(skip_all => 'Test::Pod::Coverage >= 1.04 required, skipping') if $@;

all_pod_coverage_ok(
    { coverage_class => 'Pod::Coverage::CountParents' }
);
