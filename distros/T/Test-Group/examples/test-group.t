#!perl -w
use strict;

use Test::More tests => 3;
use Test::Group;

ok(1 == 1, "normal Test::More test");

test "hammering the server" => sub {
    ok(I_can_connect());
    for(1..1000) {
        ok(I_can_make_a_request());
    }
}; # Don't forget the semicolon here!

test "TODO: not quite done yet" => sub {
    fail;
};

sub I_can_connect { 1 }
sub I_can_make_a_request { 1 }
