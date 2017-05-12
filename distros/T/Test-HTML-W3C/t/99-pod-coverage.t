#!/usr/bin/perl

use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests=>1;
pod_coverage_ok( "Test::HTML::W3C",
   { also_private => [ qr/^import.+$/ ], }, "Test::HTML::W3C pod coverage",
);
