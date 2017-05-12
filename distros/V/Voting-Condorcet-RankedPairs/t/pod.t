#!/usr/bin/perl -w
use strict;

use Test::More;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage >= 1.00 not found" if $@;

all_pod_coverage_ok();
