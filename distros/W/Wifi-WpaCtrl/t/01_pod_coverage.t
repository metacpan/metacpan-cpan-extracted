#!perl

use strict;
use warnings;
use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

all_pod_coverage_ok({
        trustme => [qr/^dl_load_flags$/],
});
