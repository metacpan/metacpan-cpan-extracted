use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 156;
use Ruby::Collections;

is_deeply(
	ra( 1, 2, 3 )->add( [ 'a', 'b', 'c' ] ),
	ra( 1, 2, 3, 'a', 'b', 'c' ),
	'Testing add()'
);

is_deeply( ra( 'a', '1' )->minus( [ 'a', 'b', 'c', 1, 2 ] ),
	ra, 'Testing minus()' );

dies_ok { ra( 1, 2, '3', 'a' )->multiply(-1) }
'Testing mutiply() with negtive argument';

is_deeply(
	ra( 1, 2, '3', 'a' )->multiply(2),
	ra( 1, 2, 3, 'a', 1, 2, 3, 'a' ),
	'Testing mutiply() with positive argument'
);

is( ra( 1, 2, '3', 'a' )->multiply(', '),
	'1, 2, 3, a', 'Testing mutiply() with string' );

is_deeply(
	ra( 'a', 'b', 'c', 1, [ 2, 3 ] )
	  ->intersection( [ '2', 'a', 'd', [ 2, 3 ] ] ),
	ra( 'a', [ 2, 3 ] ),
	'Testing intersection()'
);

is( ra()->has_all, 1, 'Testing has_all() with empty array' );

is( ra(undef)->has_all, 0, 'Testing has_all() with undef element' );

is( ra( 2, 4, 6 )->has_all( sub { $_[0] % 2 == 0 } ),
	1, 'Testing has_all() with block#1' );

is( ra( 2, 4, 7 )->has_all( sub { $_[0] % 2 == 1 } ),
	0, 'Testing has_all() with block#2' );

is( ra()->has_any, 0, 'Testing has_any() with empty array' );

is( ra(undef)->has_any, 0, 'Testing has_any() with undef element' );

is( ra( 2, 5, 7 )->has_any( sub { $_[0] % 2 == 0 } ),
	1, 'Testing has_any() with block#1' );

is( ra( 2, 4, 6 )->has_any( sub { $_[0] % 2 == 1 } ),
	0, 'Testing has_all() with block#2' );

is_deeply( ra( 1, 2, ra( 3, 4 ) )->assoc(3), ra( 3, 4 ), 'Testing assoc()' );

is( ra( 1, 2, 3, 4 )->assoc(2), undef, 'Testing assoc() with no sub arrays' );

is( ra( 1, 2, 3, 4 )->at(-2), 3, 'Testing at()' );

is( ra( 1, 2, 3, 4 )->at(4), undef, 'Testing at() with nonexist index' );

is( ra( 1, 2, 3, 4 )->bsearch( sub { $_[0] == 4 } ), 4, 'Testing bsearch()' );

is( ra( 1, 2, 3, 4 )->bsearch( sub { $_[0] == 5 } ),
	undef, 'Testing bsearch() with false condition' );

is_deeply(
	ra( 1, 3, 2, 4, 5, 6 )->chunk( sub { $_[0] % 2 } ),
	ra( [ 1, [ 1, 3 ] ], [ 0, [ 2, 4 ] ], [ 1, [5] ], [ 0, [6] ] ),
	'Testing chunk()'
);

my $ra = ra( 1, 2, 3 );
$ra->clear;
is_deeply( $ra, ra, 'Testing clear()' );

is_deeply(
	ra( 'a', 'bc', 'def' )->collect( sub { length( $_[0] ) } ),
	ra( 1,   2,    3 ),
	'Testing collect()'
);

my $ra = ra( 'a', 'bc', 'def' );
$ra->collectEx( sub { length( $_[0] ) } );
is_deeply( $ra, ra( 1, 2, 3 ), 'Testing collectEx()' );

is_deeply(
	ra( 'a',  'b',  'c' )->map( sub { $_[0] . 'd' } ),
	ra( 'ad', 'bd', 'cd' ),
	'Testing map()'
);

my $ra = ra( 'W', 'H', 'H' );
$ra->collectEx( sub { $_[0] . 'a' } );
is_deeply( $ra, ra( 'Wa', 'Ha', 'Ha' ), 'Testing mapEx()' );

is_deeply(
	ra( 1, 2, 3, 4 )->combination(2)->map( sub { $_[0]->sort } )->sort,
	ra( [ 2, 3 ], [ 2, 1 ], [ 2, 4 ], [ 3, 1 ], [ 3, 4 ], [ 1, 4 ] )
	  ->map( sub { ra( $_[0] )->sort } )->sort,
	'Testing combination()'
);

is( p_obj( ra( 1, 2, 3 )->combination( 3, sub { } ) ),
	'[1, 2, 3]', 'Testing combination() with block' );

is_deeply(
	ra( 1, undef, 3, undef, 5 )->compact,
	ra( 1, 3,     5 ),
	'Testing compact()'
);

my $ra = ra( 1, undef, 3, undef, 5 );
$ra->compactEx;
is_deeply( $ra, ra( 1, 3, 5 ), 'Testing compactEx()' );

is_deeply(
	ra( 1, 2, 3 )->concat( [ 4, [ 5, 6 ] ] ),
	ra( 1, 2, 3, 4, [ 5, 6 ] ),
	'Testing concat()'
);

is( ra( 1, 2, 3 )->count,    3, 'Testing count()' );
is( ra( 1, 2, 2 )->count(2), 2, 'Testing count()' );
is( ra( 1, 2, 3 )->count( sub { $_[0] > 0 } ), 3, 'Testing count()' );

my $ra = ra;
ra( 1, 2, 3 )->cycle( 2, sub { $ra << $_[0] + 1 } );
is_deeply( $ra, ra( 2, 3, 4, 2, 3, 4 ), 'Testing cycle()' );

is( ra( 1, 3, 5 )->delete(3), 3, 'Testing delete()' );

is( ra( 1, 2, 3 )->delete_at(2), 3, 'Testing delete_at()' );

my $ra = ra( 1, 2, 3 );
$ra->delete_if( sub { $_[0] > 2 } );
is_deeply( $ra, ra( 1, 2 ), 'Testing delete_if()' );

my $newra = ra( 1, 3, 5, 7, 9 )->drop(3);
is_deeply( $newra, ra( 7, 9 ), 'Testing drop()' );

my $newra = ra( 1, 2, 3, 4, 5, 1, 4 )->drop_while( sub { $_[0] < 2 } );
is_deeply( $newra, ra( 2, 3, 4, 5, 1, 4 ), 'Testing drop_while()' );

stdout_is(
	sub {
		ra( 1, 2, 3 )->each( sub { print $_[0] } );
	},
	'123',
	'Testing each()'
);

is_deeply(
	ra( 1, 2, 3, 4 )->each_cons(2),
	ra( ra( 1, 2 ), ra( 2, 3 ), ra( 3, 4 ) ),
	'Testing each_cons()'
);

is_deeply(
	ra( 1, 2, 3 )->each_entry->to_a,
	ra( 1, 2, 3 ),
	'Testing each_entry()'
);

is_deeply(
	ra( 1, 2, 3, 4, 5 )->each_slice(3),
	ra( ra( 1, 2, 3 ), ra( 4, 5 ) ),
	'Testing each_slice()'
);
my $newra = ra;
ra( 1, 3, 5, 7 )->each_index( sub { $newra << $_[0] } );
is_deeply( $newra, ra( 0, 1, 2, 3 ), 'Testing each_index' );

my $newra = ra;
ra( 1, 2, 3 )->each_with_index( sub { $newra << $_[1] } );
is_deeply( $newra, ra( 0, 1, 2 ), 'Testing each_with_index' );

is_deeply(
	ra( 1, 2, 3 )->each_with_object( ra, sub { $_[1] << $_[0]**2 } ),
	ra( 1, 4, 9 ),
	'Testing each_with_object'
);

is( ra( 1, 2, 3 )->is_empty(), 0, 'Testing is_empty()' );

is( ra( 1, 2, 3 )->eql( ra( 4, 5, 6 ) ), 0, 'Testing equal' );

is( ra( 1, 2, 3 )->not_eql( ra( 4, 5, 6 ) ), 1, 'Testing not_equal' );

is( ra( 1, 2, 3 )->fetch(2), 3, 'Testing fetch()' );
is( ra( 1, 2, 3 )->fetch( 5, 6 ), 6, 'Testing fetch()' );
is( ra( 1, 2, 3 )->fetch(-1), 3, 'Testing fetch()' );
dies_ok { ra( 1, 2, 3 )->fetch(5) } 'Testing fetch()';

is_deeply( ra( 1, 2, 3 )->fill(4), ra( 4, 4, 4 ), 'Testing fill' );
is_deeply(
	ra( 1, 2, 3, 4, 5 )->fill( 8, 2, 3 ),
	ra( 1, 2, 8, 8, 8 ),
	'Testing fill'
);

is_deeply(
	ra( 1, 2, 3, 4 )->fill( sub { $_[0] } ),
	ra( 0, 1, 2, 3 ),
	'Testing fill'
);

is_deeply(
	ra( 1, 2, 3, 4 )->fill( -2, sub { $_[0] + 1 } ),
	ra( 1, 2, 3, 4 ),
	'Testing fill'
);
is_deeply(
	ra( 1, 2, 3, 4 )->fill( 1, 2, sub { $_[0] + 2 } ),
	ra( 1, 3, 4, 4 ),
	'Testing fill'
);
is_deeply(
	ra( 1, 2,    3,    4 )->fill( 'ab', 1 ),
	ra( 1, 'ab', 'ab', 'ab' ),
	'Testing fill'
);

is( ra( 'a', 'b', 'c', 'b' )->find( sub { $_[0] eq 'b' } ),
	'b', 'Testing find' );

is( ra( 'a', 'b', 'c', 'b' )->find_index('b'), 1, 'Testing find_index' );

is( ra( 'a', 'b', 'c', 'b' )->find_index( sub { $_[0] eq 'b' } ),
	1, 'Testing find_index' );

is( ra( 'a', 'b', 'c', 'c' )->index('c'), 2, 'Testing index' );

is( ra( 1, 2, 3, 4 )->inject( sub { $_[0] + $_[1] } ), 10, 'Testing inject' );

is( ra( 1, 2, 3, 4 )->first, 1, 'Testing first' );

is( ra( 1, 2, 3, 4 )->first(2), ra( 1, 2 ), 'Testing first' );

is_deeply(
	ra( ra( 'a', 'b', 'c' ), ra( 'd', 'e' ) )
	  ->flat_map( sub { $_[0] + ra('f') } ),
	ra( 'a', 'b', 'c', 'f', 'd', 'e', 'f' ),
	'Testing flat_map'
);

is_deeply(
	ra( ra( 'a', 'b' ), ra( 'd', 'e' ) )->flatten,
	ra( 'a', 'b', 'd', 'e' ),
	'Testing fltten'
);

my $a = ra( ra( 'a', 'b' ), ra( 'd', 'e' ) );
$a->flattenEx;
is_deeply( $a, ra( 'a', 'b', 'd', 'e' ), 'Testing flattenEx()' );

is_deeply(
	ra( 'abbc', 'qubbn', 'accd' )->grep('bb'),
	ra( 'abbc', 'qubbn' ),
	'Testing grep()'
);

is_deeply(
	ra( 'abbc',  'qubbn', 'accd' )->grep( 'bb', sub { $_[0] . 'l' } ),
	ra( 'abbcl', 'qubbnl' ),
	'Testing grep()'
);

is_deeply(
	ra( 1, 2, 3, 4 )->group_by( sub { $_[0] % 3 } ),
	rh( 1 => [ 1, 4 ], 2 => [2], 0 => [3] ),
	'Testing group_by()'
);

is( ra( 1, 3, 5, 7, 9 )->include(9), 1, 'Testing include()' );

is_deeply(
	ra( 1, 4, 6 )->replace( ra( 2, 5 ) ),
	ra( 2, 5 ),
	'Testing replace()'
);

is_deeply(
	ra( 1, 2, 3, 4 )->insert( 2, 5 ),
	ra( 1, 2, 5, 3,              4 ),
	'Testing insert()'
);

is_deeply(
	ra( 1, 2, 3, 4 )->insert( -2, 5 ),
	ra( 1, 2, 3, 5,               4 ),
	'Testing insert()'
);

is_deeply(
	ra( 1, 2, 3, 4 )->insert( 6, 5 ),
	ra( 1, 2, 3, 4, undef, undef, 5 ),
	'Testing insert()'
);

is( ra( 1, 2, 3 )->inspect(), '[1, 2, 3]', 'Testing inspect()' );

is( ra( 1, 2, 3 )->to_s(), '[1, 2, 3]', 'Testing to_s()' );

is( ra( 'a', 'b', 'c' )->join("/"), 'a/b/c', 'Testing join()' );

is_deeply( ra( 1, 2, 3 )->keep_if( sub { $_[0] > 2 } ),
	ra(3), 'Testing keep_if()' );

is( ra( 1, 2, 3 )->last, 3, 'Testing last()' );
is_deeply( ra( 1, 2, 3 )->last(2), ra( 2, 3 ), 'Testing last()' );

is( ra( 1, 2, 3 )->length(), 3, 'Testing length()' );
is( ra()->length(), 0, 'Testing length()' );

is( ra( 1, 2, 3 )->max(), 3, 'Testing max()' );
is( ra( 1, 2, 3 )->max( sub { $_[1] <=> $_[0] } ), 1, 'Testing max()' );

is( ra( 'avv', 'aldivj', 'kgml' )->max_by( sub { length( $_[0] ) } ),
	'aldivj', 'Testing max_by' );

is( ra( 1, 2, 3 )->min(), 1, 'Testing max()' );
is( ra( 1, 2, 3 )->min( sub { $_[1] <=> $_[0] } ), 3, 'Testing max()' );

is( ra( 'kv', 'aldivj', 'kgml' )->min_by( sub { length( $_[0] ) } ),
	'kv', 'Testing min_by()' );

is_deeply( ra( 1, 2, 3 )->minmax, ra( 1, 3 ), 'Testing minmax()' );
is_deeply(
	ra( 'bbb', 'foekvv', 'rd' )
	  ->minmax( sub { length( $_[0] ) <=> length( $_[1] ) } ),
	ra( 'rd', 'foekvv' ),
	'Testing minmax()'
);

is_deeply(
	ra( 'heard', 'see', 'thinking' )->minmax_by( sub { length( $_[0] ) } ),
	ra( 'see', 'thinking' ),
	'Testing minmax_by()'
);

is( ra( 99, 43, 65 )->has_none( sub { $_[0] < 50 } ), 0, 'Testing has_none()' );
is( ra()->has_none, 1, 'Testing has_none()' );

is( ra( 99, 43, 65 )->has_one( sub { $_[0] < 50 } ), 1, 'Testing has_one()' );
is( ra(100)->has_one, 1, 'Testing has_one()' );

is_deeply(
	ra( 1, 2, 3, 4, 5, 6, 7 )->partition( sub { $_[0] % 2 == 0 } ),
	ra( ra( 2, 4, 6 ), ra( 1, 3, 5, 7 ) ),
	'Testing partition()'
);

is_deeply(
	ra( 1, 2 )->permutation->sort,
	ra( ra( 1, 2 ), ra( 2, 1 ) )->sort,
	'Testing permutation()'
);

is( ra( 1, 2, 3 )->pop, 3, 'Testing pop()' );
is_deeply( ra( 1, 2, 3 )->pop(2), ra( 2, 3 ), 'Testing pop()' );

is_deeply(
	ra( 1, 2 )->product( ra( 2, 3 ) ),
	ra( ra( 1, 2 ), ra( 1, 3 ), ra( 2, 2 ), ra( 2, 3 ) ),
	'Testing product()'
);

is_deeply( ra( 1, 2, 3 )->push( 5, 6 ), ra( 1, 2, 3, 5, 6 ), 'Testing push()' );

is_deeply(
	ra( ra( 1, 3 ), 3, ra( 2, 3 ) )->rassoc(3),
	ra( 1, 3 ),
	'Testing rassoc()'
);

is_deeply( ra( 1, 2, 3 )->reject( sub { $_[0] < 3 } ),
	ra(3), 'Testing reject()' );

my $a = ra( 1, 2, 3 )->rejectEx( sub { $_[0] < 3 } );
is_deeply( $a, ra(3), 'Testing rejectEx()' );

is_deeply(
	ra( 1, 2, 3 )->repeated_combination(2),
	ra(
		ra( 1, 1 ), ra( 1, 2 ), ra( 1, 3 ), ra( 2, 2 ), ra( 2, 3 ), ra( 3, 3 )
	),
	'Testing repeated_combination()'
);

is_deeply(
	ra( 1, 2 )->repeated_permutation(2),
	ra( ra( 1, 1 ), ra( 1, 2 ), ra( 2, 1 ), ra( 2, 2 ) ),
	'Testing repeated_permutation()'
);

is_deeply( ra( 1, 2, 3 )->reverse(), ra( 3, 2, 1 ), 'Testing reverse()' );

my $a = ra( 1, 2, 3 )->reverseEx();
is_deeply( $a, ra( 3, 2, 1 ), 'Testing reverseEx()' );

is_deeply(
	ra( 1, 2, 3 )->reverse_each( sub { $_[0] } ),
	ra( 3, 2, 1 ),
	'Testing reverse_each()'
);

is( ra( 1, 2, 3, 2, 4 )->rindex(2), 3, 'Testing rindex()' );
is( ra( 1, 2, 3, 2, 4 )->rindex( sub { $_[0] == 2 } ), 3, 'Testing rindex()' );

is_deeply( ra( 1, 2, 3 )->rotate(),   ra( 2, 3, 1 ), 'Testing rotate()' );
is_deeply( ra( 1, 2, 3 )->rotate(2),  ra( 3, 1, 2 ), 'Testing rotate()' );
is_deeply( ra( 1, 2, 3 )->rotate(-2), ra( 2, 3, 1 ), 'Testing rotate()' );

my $a = ra( 1, 2, 3 )->rotateEx();
is_deeply( $a, ra( 2, 3, 1 ), 'Testing rotate()' );
my $b = ra( 1, 2, 3 )->rotateEx(2);
is_deeply( $b, ra( 3, 1, 2 ), 'Testing rotate()' );
my $c = ra( 1, 2, 3 )->rotateEx(-2);
is_deeply( $c, ra( 2, 3, 1 ), 'Testing rotate()' );

my $a = ra( 1, 2, 3, 4 )->sample;
is( ra( 1, 2, 3, 4 )->include($a), 1, 'Testing sample()' );
my $b = ra( 1, 2, 3, 4 )->sample(4);
is_deeply( ra( 1, 2, 3, 4 ) - $b, ra(), 'Testing sample()' );

is_deeply(
	ra( 1, 4, 6, 7, 8 )->select( sub { ( $_[0] % 2 ) == 0 } ),
	ra( 4, 6, 8 ),
	'Testing select()'
);

my $a = ra( 1, 4, 6, 7, 8 );
$a->selectEx( sub { ( $_[0] % 2 ) == 0 } );
is_deeply( $a, ra( 4, 6, 8 ), 'Testing selectEx()' );

my $a = ra( 1, 2, 3 );
my $b = $a->shift;
is( $b, 1, 'Testing shift()' );
is_deeply( $a, ra( 2, 3 ), 'Testing shift()' );
my $a = ra( 1, 2, 3, 4, 5 );
my $b = $a->shift(3);
is_deeply( $b, ra( 1, 2, 3 ), 'Testing shift()' );
is_deeply( $a, ra( 4, 5 ), 'Testing shift()' );

is_deeply(
	ra( 2, 4, 6 )->unshift( 1, 3, 5 ),
	ra( 1, 3, 5, 2, 4, 6 ),
	'Testing unshift()'
);

my $a = ra( 1, 2, 3, 4, 5, 6 );
my $b = $a->shuffle();
ok( $a != $b, 'Testing shuffle()' );

my $a = ra( 1, 2, 3, 4, 5, 6 );
$a->shuffleEx();
ok( $a != ra( 1, 2, 3, 4, 5, 6 ), 'Testing shuffleEx()' );

is( ra( 1, 2, 3 )->slice(2), 3, 'Testing slice()' );
is_deeply( ra( 1, 2, 3, 4, 5 )->slice( 1, 2 ), ra( 2, 3 ), 'Testing slice()' );

my $a = ra( 1, 2, 3 );
my $b = $a->sliceEx(2);
is( $b, 3, 'Testing sliceEx()' );
is_deeply( $a, ra( 1, 2 ), 'Testing sliceEx()' );
my $a = ra( 1, 2, 3, 4, 5 );
my $b = $a->sliceEx( 1, 2 );
is_deeply( $b, ra( 2, 3 ), 'Testing sliceEx()' );
is_deeply( $a, ra( 1, 4, 5 ), 'Testing sliceEx()' );

is_deeply(
	ra( 1, 2, 3, 4, 5, 3 )->slice_before(3),
	ra( ra( 1, 2 ), ra( 3, 4, 5 ), ra(3) ),
	'Testing slice_before()'
);
is_deeply(
	ra( 1, 2, 3, 4, 5, 3 )->slice_before( sub { $_[0] % 3 == 0 } ),
	ra( ra( 1, 2 ), ra( 3, 4, 5 ), ra(3) ),
	'Testing slice_before()'
);

is_deeply(
	ra( 1, 3, 5, 2, 7, 0 )->sort,
	ra( 0, 1, 2, 3, 5, 7 ),
	'Testing sort()'
);
is_deeply(
	ra( 'djh', 'kdirhf', 'a' )
	  ->sort( sub { length( $_[0] ) <=> length( $_[1] ) } ),
	ra( 'a', 'djh', 'kdirhf' ),
	'Testing sort()'
);

my $a = ra( 1, 3, 5, 2, 7, 0 );
my $b = $a->sortEx;
is_deeply( $a, ra( 0, 1, 2, 3, 5, 7 ), 'Testing sortEx()' );
is_deeply( $b, ra( 0, 1, 2, 3, 5, 7 ), 'Testing sortEx()' );
my $a = ra( 'djh', 'kdirhf', 'a' );
my $b = $a->sortEx( sub { length( $_[0] ) <=> length( $_[1] ) } );
is_deeply( $a, ra( 'a', 'djh', 'kdirhf' ), 'Testing sortEx()' );
is_deeply( $b, ra( 'a', 'djh', 'kdirhf' ), 'Testing sortEx()' );

is_deeply(
	ra( 2, 3, 7, 89, 6 )->sort_by( sub { $_[0] - 2 } ),
	ra( 2, 3, 6, 7,  89 ),
	'Testing sort_by()'
);

my $a = ra( 2, 3, 7, 89, 6 );
my $b = $a->sort_byEx( sub { $_[0] - 2 } );
is_deeply( $a, ra( 2, 3, 6, 7, 89 ), 'Testing sort_byEx()' );
is_deeply( $b, ra( 2, 3, 6, 7, 89 ), 'Testing sort_byEx()' );

is_deeply( ra( 3, 5, 6, 7, 8, 9 )->take(2), ra( 3, 5 ), 'Testing take()' );

is_deeply(
	ra( 2, 4, 3, 6, 7, 8, 2 )->take_while( sub { $_[0] < 5 } ),
	ra( 2, 4, 3 ),
	'Testing take_while()'
);

is_deeply(
	ra( 2, 4, 6, 7, 8, 9 )->to_a,
	ra( 2, 4, 6, 7, 8, 9 ),
	'Testing to_a()'
);

is_deeply(
	rh( 2 => 4, 4 => 5, 6 => 7 )->entries,
	ra( ra( 2, 4 ), ra( 4, 5 ), ra( 6, 7 ) ),
	'Testing entries()'
);

my $a = ra( 1, 2, 3 );
my $b = ra( 4, 5, 6 );
my $c = ra( 7, 8 );
is_deeply(
	$a->zip($b),
	ra( ra( 1, 4 ), ra( 2, 5 ), ra( 3, 6 ) ),
	'Testing zip()'
);

is_deeply(
	$a->zip($c),
	ra( ra( 1, 7 ), ra( 2, 8 ), ra( 3, undef ) ),
	'Testing zip()'
);

is_deeply(
	ra( 1, 3, 4 )->union( ra( 2, 4, 6 ) ),
	ra( 1, 3, 4,                 2, 6 ),
	'Testing union()'
);
