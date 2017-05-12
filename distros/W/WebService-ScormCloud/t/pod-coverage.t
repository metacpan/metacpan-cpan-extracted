#!perl -T

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_AUTHOR})
{
    plan skip_all => 'Set $ENV{TEST_AUTHOR} to a true value to run POD tests.';
}

my $min_tpc = 1.08;

eval "use Test::Pod::Coverage $min_tpc";
if ($@)
{
    plan skip_all =>
      "Test::Pod::Coverage $min_tpc required to test POD coverage.";
}

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles:
#
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
if ($@)
{
    plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage.";
}

all_pod_coverage_ok();

