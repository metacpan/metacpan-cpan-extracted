use strict;
use warnings;

use Test::More tests => 12;
use URI::Query::FromHash;

my %args = ( a => 'b' );

is hash2query(%args), 'a=b', 'hash2query %args';
is hash2query(\%args), 'a=b', 'hash2query \%args';
is hash2query({ a => 'b' }), 'a=b', 'hash2query { a => "b" }';

is hash2query(''),    '', 'hash2query ""';
is hash2query({}),    '', 'hash2query {}';
is hash2query(undef), '', 'hash2query undef';

is hash2query( { a => 1, b => 2 } ), 'a=1&b=2', 'hash2query { a => 1, b => 2 }';

is hash2query( { a => [] } ), '', 'hash2query { a => [] }';
is hash2query( { a => 'b', c => [] } ), 'a=b',
    'hash2query { a => "b", c => [] }';

is hash2query( { a => [ 11..15 ] } ), 'a=11&a=12&a=13&a=14&a=15',
    'hash2query { a => [ 11..15 ] }';

is hash2query( { a => undef } ), 'a=', 'hash2query( { a => undef }';
is hash2query( { a => [1, undef, 2] } ), 'a=1&a=&a=2',
    'hash2query( { a => [1, undef, 2] }';
