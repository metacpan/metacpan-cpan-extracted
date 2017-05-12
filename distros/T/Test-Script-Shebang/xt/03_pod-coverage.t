use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_POD_COVERAGE}) {
    plan skip_all => "\$ENV{TEST_POD_COVERAGE} is not set.";
    exit;
}

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

all_pod_coverage_ok({also_private => [qw(unimport BUILD DEMOLISH)]});
