use strict;
use warnings;

use Test::More;

plan skip_all => 'Not running under Travis'
    unless $ENV{TRAVIS};

my @travis_keys = grep { /^encrypted_.+_(iv|key)$/ } keys %ENV;

pass "potential variables: @travis_keys";

ok !$ENV{$_} => "$_ is empty, undef, 0, or otherwise falsey"
    for @travis_keys;

done_testing;
