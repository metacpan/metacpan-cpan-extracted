#!perl -T
use strict;
use Test::More;

plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    unless eval "use Test::Pod::Coverage 1.04; 1";

plan tests => 1;
pod_coverage_ok(XSLoader => {also_private => ['^bootstrap_inherit$']});
