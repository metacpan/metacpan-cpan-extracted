#!perl -w

use Test::More;
use lib 'lib';
use Tie::Hash::MultiValue;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
