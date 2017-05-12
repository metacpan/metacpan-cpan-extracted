#!perl

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

eval "use Pod::Coverage::TrustPod";
plan skip_all => "Pod::Coverage::TrustPod required for testing POD coverage"
  if $@;

my @mods = grep { not /private/ } all_modules();
plan tests => scalar(@mods);
pod_coverage_ok($_, { coverage_class => 'Pod::Coverage::TrustPod' }) 
    foreach @mods;

