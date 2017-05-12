#!perl -w
use strict;
use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok( "Unicode::ICU::Collator",
	       {
		also_private => [ "constant" ]
	       });
