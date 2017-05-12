#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
use Test::Pod::Coverage 1.08;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
use Pod::Coverage 0.18;

all_pod_coverage_ok();
