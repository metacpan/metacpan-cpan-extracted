#!/usr/bin/perl
# $Id: pod-coverage.t 1582 2007-03-22 13:45:11Z guillomovitch $

use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan(skip_all => 'Test::Pod::Coverage >= 1.04 required, skipping') if $@;

all_pod_coverage_ok(
    { coverage_class => 'Pod::Coverage::CountParents' }
);
