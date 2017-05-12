#!/usr/bin/perl
use strict;
use warnings;

use WWW::xkcd;
use Test::More tests => 4;
use Test::Fatal;

my $x = WWW::xkcd->new;
isa_ok( $x, 'WWW::xkcd'    );
can_ok( $x, '_decode_json' );

is_deeply(
    $x->_decode_json( q({"hello":"world"}) ),
    { hello => 'world' },
    '_decode_json decodes successfully',
);

ok(
    exception { $x->_decode_json( q({helwhatZZ--}}) ) },
    'Failed to decode successfully',
);

