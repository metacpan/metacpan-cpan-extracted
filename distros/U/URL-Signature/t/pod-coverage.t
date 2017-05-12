#!perl -T

use Test::More;
plan skip_all => 'set DEVELOPER_TESTS to enable this test (developer only!)'
  unless $ENV{DEVELOPER_TESTS};

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

all_pod_coverage_ok( { also_private => [ qr/BUILD/ ] } );
