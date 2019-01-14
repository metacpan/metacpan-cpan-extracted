#!perl

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        print qq{1..0 # SKIP these tests are for release candidate testing\n};
        exit;
    }
}

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

eval "use Pod::Coverage::TrustPod";
plan skip_all => "Pod::Coverage::TrustPod required for testing POD coverage"
  if $@;

# test public modules only
plan tests => 1;
pod_coverage_ok( 'Test::Mocha',
    { coverage_class => 'Pod::Coverage::TrustPod' } )
