#!/usr/bin/perl
# $Id: pod.t 2318 2011-01-22 12:59:02Z guillomovitch $

use strict;
use warnings;
use Test::More;

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    unless $ENV{TEST_AUTHOR};

eval "use Test::Pod 1.14";
plan(skip_all => 'Test::Pod >= 1.14 required, skipping') if $@;

all_pod_files_ok();
