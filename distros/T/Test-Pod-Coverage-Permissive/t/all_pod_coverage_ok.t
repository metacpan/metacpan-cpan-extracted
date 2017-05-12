#!perl -T

# This is the most basic form that most people will use.
use Test::More;
use Test::Pod::Coverage::Permissive;
all_pod_coverage_ok();
done_testing();
