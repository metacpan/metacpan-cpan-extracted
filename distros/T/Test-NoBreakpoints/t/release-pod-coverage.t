
BEGIN {
    use Test::More;
    unless ($ENV{RELEASE_TESTING}) {
        plan skip_all => 'Release test. Set $ENV{RELEASE_TESTING} to a true value to run.';
    }
}

use strict;
use warnings;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required to criticise code" if $@;

eval "use Pod::Coverage::TrustPod";
plan skip_all => "Pod::Coverage::TrustPod required to criticise code" if $@;

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });
