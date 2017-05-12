#!perl
use Test::More tests => 4;
use strict;
use warnings;
use lib 't';

# This tests that each pragma works but also that they don't overlap.
use pragma foo => 42;
use XXX foo    => 43;
is( scalar pragma->peek('foo'), '42', q[...] );
is( scalar XXX->peek('foo'),    '43', q[use XXX foo => 1] );

TODO: {
    local $TODO = 'valueless syntax missing';
    use XXX 'foo';
    is( scalar XXX->peek('foo'), '1', q[use XXX foo => 1] );
}

no XXX 'foo';
is( scalar XXX->peek('foo'), undef, q[no XXX 'foo'] );
