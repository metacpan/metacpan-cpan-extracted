#!perl

use strict;
use warnings;
use Test::More;

my $MODULE = 'Test::Pod::Coverage 1.00';

# Don't run tests for installs
unless ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
    plan(skip_all => "Author tests not required for installation");
}

# Load the testing module
eval "use $MODULE";
if ($@) {
    $ENV{RELEASE_TESTING}
      ? die("Failed to load required release-testing module $MODULE")
      : plan(skip_all => "$MODULE not available for testing");
}

my $trustparents = {coverage_class => 'Pod::Coverage::CountParents'};
all_pod_coverage_ok($trustparents);
