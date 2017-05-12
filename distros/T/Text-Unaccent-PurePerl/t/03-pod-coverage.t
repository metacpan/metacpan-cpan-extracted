# -*- mode: perl; coding: us-ascii-unix -*-
#
# Author:      Peter John Acklam
# Time-stamp:  2013-03-01 13:39:37 +00:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

#########################

#use 5.008;              # for UTF-8 support
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
#use utf8;               # enable/disable UTF-8 (or UTF-EBCDIC) in source code

use Test::More;         # yet another framework for writing test scripts

# Ensure a recent version of Test::Pod::Coverage

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

all_pod_coverage_ok();
