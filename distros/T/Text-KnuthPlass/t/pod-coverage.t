#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
  unless ($ENV{'AUTHOR_TESTING'}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test::More;

use Text::KnuthPlass;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval { use Test::Pod::Coverage $min_tpc };
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval { use Pod::Coverage $min_pc };
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

all_pod_coverage_ok();

1;
