use strict;
use warnings;
use Test::More;
use Class::Load qw(try_load_class);

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
try_load_class('Test::Pod::Coverage', {-version => $min_tpc})
    or plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage";

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
try_load_class('Pod::Coverage', {-version => $min_pc})
    or plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage";

Test::Pod::Coverage::all_pod_coverage_ok({also_private => ['BUILDARGS'],});
