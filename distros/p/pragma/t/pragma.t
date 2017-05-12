#!perl
use Test::More tests => 7;
use strict;
use warnings;

BEGIN { use_ok('pragma') }

# This will succeed anyway on perls without user pragmata.
is( scalar pragma->peek('test'),
    undef, 'Undefined pragmas return empty lists' );
is( scalar @{ [ pragma->peek('test') ] },
    0, 'Undefined pragmas return empty lists' );

TODO: {
    local $TODO = 'valueless syntax missing';
    use pragma 'test';
    is( scalar pragma->peek('test'), '1', q[use pragma 'test';] );
}

use pragma test => 42;
is( scalar pragma->peek('test'), 42, 'use pragma test => ...' );

BEGIN { pragma->poke( test => 43 ) }
is( scalar pragma->peek('test'), 43, 'pragma->poke( test => ... )' );

# This will succeed anyway on perls without user pragmata.
no pragma 'test';
is( scalar pragma->peek('test'), undef, q[no pragma 'test'] );
