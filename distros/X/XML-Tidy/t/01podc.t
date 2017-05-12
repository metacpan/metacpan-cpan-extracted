use Test::More;
eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing POD Coverage' if $@;
plan tests    => 1;
pod_coverage_ok('XML::Tidy','POD Covered');
