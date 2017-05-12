#!perl

use Test::More;

eval "use Test::MinimumVersion";
plan skip_all => "Test::MinimumVersion required for testing minimum versions"
  if $@;
all_minimum_version_ok( qq{5.006} , { skip => [qw(t/given_when.t t/when.t)] });
