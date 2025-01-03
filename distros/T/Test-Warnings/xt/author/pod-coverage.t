use strict;
use warnings;

use Test::More 0.94;
use Test::Pod::Coverage 1.08;
use Pod::Coverage::TrustPod;

subtest all_pod_coverage_ok => sub {
    all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });
};

Test::Warnings->import(':no_end_test');
done_testing;
