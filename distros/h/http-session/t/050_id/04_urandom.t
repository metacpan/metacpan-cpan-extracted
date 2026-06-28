use strict;
use warnings;
use Test::More tests => 12;
require HTTP::Session::ID::Urandom;

is(length(HTTP::Session::ID::Urandom->generate_id(10)), 10, 'check length');
cmp_ok(HTTP::Session::ID::Urandom->generate_id(10), 'ne', HTTP::Session::ID::Urandom->generate_id(10), 'unique');

for my $len (1, 2, 3, 4, 10, 16, 32, 40, 63, 64) {
    is(length(HTTP::Session::ID::Urandom->generate_id($len)), $len,
        "generate_id($len) returns exactly $len chars");
}
