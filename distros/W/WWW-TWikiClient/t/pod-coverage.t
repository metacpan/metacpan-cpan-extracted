#! perl -Tw

use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

unless ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
	plan skip_all => "Author tests not required for installation";
}

all_pod_coverage_ok();
