#!perl -T

use Test2::V0;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok({
    also_private => [ qr[^unimport$] ]
});
