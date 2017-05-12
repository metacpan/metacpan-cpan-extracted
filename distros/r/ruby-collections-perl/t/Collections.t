use strict;
use Scalar::Util qw(reftype);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 20;

use_ok('Ruby::Collections::Array');
use_ok('Ruby::Collections::Hash');
use_ok('Ruby::Collections');

is( ref( ra() ), 'Ruby::Collections::Array', 'Testing ra() raw type' );

is( reftype( ra() ), 'ARRAY', 'Testing ra() basic type' );

is( ra( 1, 2, 3 )->to_s, p_obj( [ 1, 2, 3 ] ), 'Testing ra() with arguments' );

is(
	ra( [ 1, 2, 3 ] )->to_s,
	p_obj( [ 1, 2, 3 ] ),
	'Testing ra() with array ref'
);

is(
	ra( ra( 1, 2, 3 ) )->to_s,
	p_obj( [ [ 1, 2, 3 ] ] ),
	'Testing ra() with ra()'
);

is( ref( rh() ), 'Ruby::Collections::Hash', 'Testing rh() raw type' );

is( reftype( rh() ), 'HASH', 'Testing rh() basic type' );

is_deeply(
	rh( 1, 'a', 2, 'b' ),
	{ 1 => 'a', 2 => 'b' },
	'Testing rh() with arguments'
);

is_deeply(
	rh( 1 => 'a', 2 => 'b' ),
	{ 1 => 'a', 2 => 'b' },
	'Testing rh() with arguments and arrow symbols'
);

dies_ok { rh( 1, 'a', 2, 'b', 3 ) } 'Testing rh() with odd arguments';

is_deeply(
	rh( { 1 => 'a', 2 => 'b' } ),
	{ 1 => 'a', 2 => 'b' },
	'Testing rh() with hash ref'
);

stdout_is(
	sub {
		p( { 'a' => [ 1, { 'b' => 2 }, 3, { 'c' => 4 } ] } );
	},
	"{a=>[1, {b=>2}, 3, {c=>4}]}\n",
	'Testing p() with complex data structure'
);

stdout_is(
	sub { p( [ 1, undef, 'a' ] ) },
	"[1, undef, a]\n",
	'Testing p() with undefined element'
);

is(
	p_obj( { 'a' => [ 1, { 'b' => 2 }, 3, { 'c' => 4 } ] } ),
	"{a=>[1, {b=>2}, 3, {c=>4}]}",
	'Testing p_obj() with complex data structure'
);

is(
	p_obj( [ 1, undef, 'a' ] ),
	"[1, undef, a]",
	'Testing p_obj() with undefined element'
);

is(
	p_array( [ 1, undef, 'a', { 2 => 'b' } ] ),
	'[1, undef, a, {2=>b}]',
	'Testing p_array()'
);

is(
	p_hash( { 1 => [ 'a', undef, { 2 => 'b' } ] } ),
	'{1=>[a, undef, {2=>b}]}',
	'Testing p_hash()'
);
