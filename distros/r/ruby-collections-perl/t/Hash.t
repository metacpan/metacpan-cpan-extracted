use strict;
use Scalar::Util qw(looks_like_number);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 122;
use Ruby::Collections;

is( rh( undef => 2 )->has_all, 1, 'Testing has_all()' );

is( rh( 'a' => 1, '2' => 'b' )->has_all( sub { looks_like_number $_[0] } ),
	0, 'Testing has_all() with block' );

is( rh( 1 => 2 )->has_any, 1, 'Testing has_any()' );

is( rh->has_any, 0, 'Testing has_any() with empty hash' );

is( rh( 2 => 4, 6 => 8 )->has_any( sub { $_[0] % 2 == 1 } ),
	0, 'Testing has_any() with block' );

is_deeply(
	rh( 'a' => 123, 'b' => 456 )->assoc('b'),
	ra( 'b', 456 ),
	'Testing assoc()'
);

is( rh( 'a' => 123, 'b' => 456 )->assoc('c'),
	undef, 'Testing assoc() with nonexist key' );

is_deeply(
	rh( 1 => 1, 2 => 2, 3 => 3, 5 => 5, 4 => 4 )->chunk( sub { $_[0] % 2 } ),
	ra(
		[ 1, [ [ 1, 1 ] ] ],
		[ 0, [ [ 2, 2 ] ] ],
		[ 1, [ [ 3, 3 ], [ 5, 5 ] ] ],
		[ 0, [ [ 4, 4 ] ] ]
	),
	'Testing chunk()'
);

my $rh = rh( 1 => 2, 3 => 4 );
$rh->clear;
is_deeply( $rh, rh, 'Testing clear()' );

is( rh( 'a' => 1 )->delete('a'), 1, 'Testing delete()' );

is( rh( 'a' => 1 )->delete('b'), undef, 'Testing delete() with nonexist key' );

is( rh( 'a' => 1 )->delete( 'a', sub { $_[0] * 3 } ),
	3, 'Testing delete() with block' );

is( rh( 'a' => 'b', 'c' => 'd' )->count, 2, 'Testing count()' );

is(
	rh( 1 => 3, 2 => 4, 5 => 6 )->count(
		sub {
			my ( $key, $val ) = @_;
			$key % 2 == 0 && $val % 2 == 0;
		}
	),
	1,
	'Testing count() with block'
);

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4 )->cycle( 1, sub { print "$_[0], $_[1], " } );
	},
	'1, 2, 3, 4, ',
	'Testing cycle() with limit'
);

dies_ok { rh( 1 => 2, 3 => 4 )->cycle( 1, 2, 3 ) }
'Testing cycle() with wrong number of arguments';

my $rh = rh( [ 1, 5 ] => 3, 2 => 4 );
$rh->delete_if(
	sub {
		my ( $key, $val ) = @_;
		$key eq p_obj( [ 1, 5 ] );
	}
);
is_deeply( $rh, rh( 2 => 4 ), 'Testing delete_if()' );

is_deeply(
	rh( 1 => 'a', undef => 0, 'b' => 2 )->drop(1),
	ra( [ 'undef', 0 ], [ 'b', 2 ] ),
	'Testing drop()'
);

dies_ok { rh( 1 => 'a', undef => 0, 'b' => 2 )->drop(-2) }
'Test drop() with negative aize';

is_deeply(
	rh( 0 => 2, 1 => 3, 2 => 4, 5 => 7 )->drop_while(
		sub {
			my ( $key, $val ) = @_;
			$key % 2 == 1;
		}
	),
	ra( [ 1, 3 ], [ 2, 4 ], [ 5, 7 ] ),
	'Testing drop_while()'
);

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4 )->each(
			sub {
				my ( $key, $val ) = @_;
				print "$key, $val, ";
			}
		);
	},
	'1, 2, 3, 4, ',
	'Testing each()'
);

is_deeply(
	rh( 1 => 2, 3 => 4 )->each(
		sub {
			my ( $key, $val ) = @_;
			$key + $val;
		}
	),
	rh( 1 => 2, 3 => 4 ),
	'Testing each() return value'
);

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4, 5 => 6 )->each_cons(
			2,
			sub {
				my ($sub_ary) = @_;
				p $sub_ary->[0]->zip( $sub_ary->[1] );
			}
		);
	},
	"[[1, 3], [2, 4]]\n[[3, 5], [4, 6]]\n",
	'Testing each_cons()'
);

dies_ok { rh( 1 => 2, 3 => 4, 5 => 6 )->each_cons(0) }
'Testing each_cons() with invalid size';

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4 )->each(
			sub {
				my ( $key, $val ) = @_;
				print "$key, $val, ";
			}
		);
	},
	'1, 2, 3, 4, ',
	'Testing each_entry()'
);

is_deeply(
	rh( 1 => 2, 3 => 4 )->each(
		sub {
			my ( $key, $val ) = @_;
			$key + $val;
		}
	),
	rh( 1 => 2, 3 => 4 ),
	'Testing each_entry() return value'
);

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4 )->each(
			sub {
				my ( $key, $val ) = @_;
				print "$key, $val, ";
			}
		);
	},
	'1, 2, 3, 4, ',
	'Testing each_pair()'
);

is_deeply(
	rh( 1 => 2, 3 => 4 )->each(
		sub {
			my ( $key, $val ) = @_;
			$key + $val;
		}
	),
	rh( 1 => 2, 3 => 4 ),
	'Testing each_pair() return value'
);

is_deeply(
	rh( 1 => 2, 3 => 4, 5 => 6 )->each_slice(2),
	ra( [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ] ] ),
	'Testing each_slice()'
);

dies_ok { rh( 1 => 2, 3 => 4, 5 => 6 )->each_slice(0) }
'Testing each_slice() with invalid slice siz';

stdout_is(
	sub {
		rh( 1 => 2, 'a' => 'b', [ 3, { 'c' => 'd' } ] => 4 )->each_key(
			sub {
				print "$_[0], ";
			}
		);
	},
	'1, a, [3, {c=>d}], ',
	'Testing each_key()'
);

stdout_is(
	sub {
		rh( 1 => 2, 'a' => undef, '3' => rh( [2] => [3] ) )->each_value(
			sub {
				print p_obj( $_[0] ) . ', ';
			}
		);
	},
	'2, undef, {[2]=>[3]}, ',
	'Testing each_value()'
);

stdout_is(
	sub {
		rh( 'a' => 'b', 'c' => 'd' )->each_with_index(
			sub {
				my ( $key, $val, $index ) = @_;
				print "$key, $val, $index, ";
			}
		);
	},
	'a, b, 0, c, d, 1, ',
	'Testing each_with_index()'
);

stdout_is(
	sub {
		my $ra = ra;
		rh( 1 => 2, 3 => 4 )->each_with_object(
			$ra,
			sub {
				my ( $key, $val, $obj ) = @_;
				$obj->push( $key, $val );
			}
		);
		p $ra;
	},
	"[1, 2, 3, 4]\n",
	'Testing each_with_object()'
);

is( rh->is_empty, 1, 'Testing is_empty()' );

is( rh( 1 => undef )->is_empty, 0, 'Testing is_empty() with undef value' );

is( rh( undef => 1 )->is_empty, 0, 'Testing is_empty() with undef key' );

is_deeply(
	rh( 1 => 2, 3 => 4 )->entries,
	ra( [ 1, 2 ], [ 3, 4 ] ),
	'Testing entries()'
);

is( rh( 1 => 2, 3 => 4, 5 => 6 )->eql( { 5 => 6, 3 => 4, 1 => 2 } ),
	1, 'Testing eql()' );

is(
	rh( [ 1, 2 ] => 3, [4] => [ 5, 6 ] )
	  ->eql( rh( [ 1, 2 ] => 3, [4] => [ 5, 6 ] ) ),
	1,
	'Testing eql() with Ruby::Hash'
);

is(
	rh( [ 1, 2 ] => 3, [4] => [ 5, 6 ] )
	  ->eql( { [ 1, 2 ] => 3, [4] => [ 5, 6 ] } ),
	0,
	'Testing eql() with Perl hash'
);

is( rh( 1 => 2, 3 => 4 )->fetch(1), 2, 'Testing fetch()' );

dies_ok { rh( 1 => 2, 3 => 4 )->fetch(5) } 'Testing fetch with nonexist key';

is( rh( 1 => 2, 3 => 4 )->fetch( 5, 10 ),
	10, 'Testing fetch() with default value' );

is( rh( 1 => 2, 3 => 4 )->fetch( 5, sub { $_[0] * $_[0] } ),
	25, 'Testing fetch() with block' );

is_deeply(
	rh( 'a' => 1, 'b' => 2 )->find(
		sub {
			my ( $key, $val ) = @_;
			$val % 2 == 0;
		}
	),
	ra( 'b', 2 ),
	'Testing find()'
);

dies_ok { rh( 'a' => 1, 'b' => 2 )->detect( 1, 2, 3 ) }
'Testing detect() with wrong number of arguments';

is(
	rh( 'a' => 1, 'b' => 2 )->find(
		sub { 'Not Found!' },
		sub {
			my ( $key, $val ) = @_;
			$val % 2 == 3;
		}
	),
	'Not Found!',
	'Testing find() with default value'
);

is_deeply(
	rh( 'a' => 'b', 1 => 2, 'c' => 'd', [ 3, 4 ] => 5 )->find_all(
		sub {
			my ( $key, $val ) = @_;
			$key eq '[3, 4]';
		}
	),
	ra( ra( '[3, 4]', 5 ) ),
	'Testing find_all()'
);

is( rh( 1 => 2, 3 => 4 )->find_index( [ 3, 4 ] ), 1, 'Testing find_index()' );

is( rh( 1 => 2, 3 => 4 )->find_index( [ 5, 6 ] ),
	undef, 'Testing find_index() with nonexist pair' );

is( rh( 1 => 2, 3 => 4 )->find_index( sub { $_[0] == 3 } ),
	1, 'Testing find_index() with block' );

is_deeply( rh( 1 => 2, 3 => 4 )->first, ra( 1, 2 ), 'Testing first()' );

is_deeply(
	rh( 1 => 2, 3 => 4 )->first(5),
	ra( [ 1, 2 ], [ 3, 4 ] ),
	'Testing first() with n'
);

dies_ok { rh( 1 => 2, 3 => 4 )->first(-1) }
'Testing first() with negative array size';

is_deeply(
	rh( 1 => 2, 3 => 4 )->flat_map( sub { [ $_[0] * $_[1] * 10 ] } ),
	ra( 20, 120 ),
	'Testing flat_map()'
);

is_deeply(
	rh( 1 => 2, 3 => 4 )->collect_concat( sub { [ [ $_[0] * $_[1] ] ] } ),
	ra( [2], [12] ),
	'Testing collect_concat()'
);

is_deeply(
	rh( 1 => [ 2, 3 ], 4 => 5 )->flatten,
	ra( 1, [ 2, 3 ], 4, 5 ),
	'Testing flatten()'
);

is_deeply(
	rh( 1 => [ 2, 3 ], 4 => 5 )->flatten(2),
	ra( 1, 2, 3, 4, 5 ),
	'Testing flatten() with n'
);

is_deeply(
	rh( 'a' => 1, '2' => 'b', 'c' => 3 )->grep(qr/^\[[a-z]/),
	ra( [ 'a', 1 ], [ 'c', 3 ] ),
	'Testing grep()'
);

is_deeply(
	rh( 'a' => 1, '2' => 'b', 'c' => 3 )->grep(
		qr/^\[[a-z]/,
		sub {
			$_[0]->push('z');
		}
	),
	ra( [ 'a', 1, 'z' ], [ 'c', 3, 'z' ] ),
	'Testing grep() with block'
);

is_deeply(
	rh( 1 => 3, 0 => 4, 2 => 5 )->group_by(
		sub {
			$_[0] + $_[1];
		}
	),
	{ 4 => [ [ 1, 3 ], [ 0, 4 ] ], 7 => [ [ 2, 5 ] ] },
	'Testing group_by()'
);

is( rh( 1 => 2, [ 3, { 4 => 5 } ] => 5, undef => 6 )->include(1),
	1, 'Testing include()' );

is(
	rh( 1 => 2, [ 3, { 4 => 5 } ] => 5, undef => 6 )
	  ->include( [ 3, { 4 => 5 } ] ),
	1,
	'Testing include() with array & hash'
);

is( rh( 1 => 2, [ 3, { 4 => 5 } ] => 5, undef => 6 )->has_key(1),
	1, 'Testing has_key() with undef' );

is( rh( 1 => 2, [ 3, { 4 => 5 } ] => 5, undef => 6 )->has_member(1),
	1, 'Testing has_member() with nonexist key' );

is_deeply(
	rh( 1 => 2, 3 => 4, 5 => 6 )->inject(
		sub {
			my ( $o, $i ) = @_;
			@$o[0] += @$i[0];
			@$o[1] += @$i[1];
			$o;
		}
	),
	ra( 9, 12 ),
	'Testing inject()'
);

is_deeply(
	rh( 1 => 2, 3 => 4, 5 => 6 )->reduce(
		[ 7, 7 ],
		sub {
			my ( $o, $i ) = @_;
			@$o[0] += @$i[0];
			@$o[1] += @$i[1];
			$o;
		}
	),
	[ 16, 19 ],
	'Testing reduce() with init value'
);

is(
	rh( [ 1, 2 ] => 3, 'a' => 'b' )->inspect,
	'{[1, 2]=>3, a=>b}',
	'Testing inspect()'
);

is_deeply(
	rh( 1   => 'a', 2   => 'b', 3 => 'a' )->invert,
	rh( 'a' => 3,   'b' => 2 ),
	'Testing invert()'
);

is_deeply(
	rh( 1 => 1, 2 => 2, 3 => 3 )->keep_if( sub { $_[0] % 2 == 1 } ),
	rh( 1 => 1, 3 => 3 ),
	'Testing keep_if()'
);

is( rh( 1 => 2, 3 => 2 )->key(2), 1, 'Testing key()' );

is( rh( 1 => 2, 3 => 2 )->key(4), undef, 'Testing key() with nonexist value' );

is_deeply( rh( 1 => 2, 3 => 4, 5 => 6 )->keys, ra( 1, 3, 5 ),
	'Testing keys()' );

is( rh( 1 => 2, 3 => 4 )->length, 2, 'Testing length()' );

is( rh->size, 0, 'Testing size()' );

is_deeply(
	rh( 1 => 2, 3 => 4 )->map( sub { $_[0] + $_[1] } ),
	ra( 3, 7 ),
	'Testing map()'
);

is_deeply(
	rh( 1 => 2, 3 => 4 )->collect( sub { $_[0] * $_[1] } ),
	ra( 2, 12 ),
	'Testing collect()'
);

is_deeply( rh( 6 => 5, 11 => 3, 2 => 1 )->max, ra( 6, 5 ), 'Testing max()' );

is_deeply(
	rh( 6 => 5, 11 => 3, 2 => 1 )
	  ->max( sub { @{ $_[0] }[0] <=> @{ $_[1] }[0] } ),
	ra( 11, 3 ),
	'Testing max() with block'
);

is_deeply(
	rh( 6 => 5, 11 => 3, 2 => 20 )
	  ->max_by( sub { @{ $_[0] }[0] + @{ $_[0] }[1] } ),
	ra( 2, 20 ),
	'Testing max_by()'
);

is_deeply(
	rh( 1 => 2, 3 => 4 )->merge( { 3 => 3, 4 => 5 } ),
	rh( 1 => 2, 3 => 3,          4   => 5 ),
	'Testing merge()'
);

my $rh = rh( 1 => 2, 3 => 4 );
$rh->mergeEx( { 3 => 3, 4 => 5 } );
is_deeply( $rh, rh( 1 => 2, 3 => 3, 4 => 5 ), 'Testing mergeEx()' );

is_deeply( rh( 6 => 5, 11 => 3, 2 => 1 )->min, ra( 11, 3 ), 'Testing min()' );

is_deeply(
	rh( 6 => 5, 11 => 3, 2 => 1 )->min(
		sub {
			@{ $_[0] }[1] - @{ $_[0] }[0] <=> @{ $_[1] }[1] - @{ $_[1] }[0];
		}
	),
	ra( 11, 3 ),
	'Testing min() with block'
);

is_deeply(
	rh( 6 => 5, 11 => 3, 2 => 20 )
	  ->min_by( sub { @{ $_[0] }[0] + @{ $_[0] }[1] } ),
	ra( 6, 5 ),
	'Testing min_by()'
);

is_deeply(
	rh( 1 => 10, 2 => 9, 3 => 8 )->minmax,
	ra( [ 1, 10 ], [ 3, 8 ] ),
	'Testing minmax()'
);

is_deeply(
	rh( 1 => 10, 2 => 9, 3 => 8 )->minmax(
		sub {
			@{ $_[0] }[1] - @{ $_[0] }[0] <=> @{ $_[1] }[1] - @{ $_[1] }[0];
		}
	),
	ra( [ 3, 8 ], [ 1, 10 ] ),
	'Testing minmax() with block'
);

is_deeply(
	rh( 6 => 5, 11 => 3, 2 => 20 )
	  ->minmax_by( sub { @{ $_[0] }[0] * @{ $_[0] }[1] } ),
	ra( [ 6, 5 ], [ 2, 20 ] ),
	'Testing mnimax_by()'
);

is( rh->has_none, 1, 'Testing has_none()' );

is( rh( 1 => 2 )->has_none, 0, 'Testing has_none() with nonempty hash' );

is( rh( 'a' => 'b' )->has_none( sub { looks_like_number( $_[0] ) } ),
	1, 'Testing has_none() with block' );

is( rh( 1 => 2 )->has_one, 1, 'Testing has_one()' );

is( rh->has_one, 0, 'Testing has_one() with empty hash' );

is( rh( 'a' => 'b', 1 => 2 )->has_one( sub { looks_like_number( $_[0] ) } ),
	1, 'Testing has_one() with block' );

is_deeply(
	rh( 'a' => 1, 2 => 'b', 'c' => 3, 4 => 'd' )->partition(
		sub {
			looks_like_number( $_[0] );
		}
	),
	ra( [ [ 2, 'b' ], [ 4, 'd' ] ], [ [ 'a', 1 ], [ 'c', 3 ] ] ),
	'Testing partition()'
);

is_deeply(
	rh( 'a' => 123, 'b' => 123 )->rassoc(123),
	ra( 'a', 123 ),
	'Testing rassoc()'
);

is( rh( 'a' => 123, 'b' => 123 )->rassoc(456),
	undef, 'Testing rassoc() with nonexist key' );

is(
	rh( 1 => 3, 2 => 4, 5 => 6 )->reject(
		sub {
			my ( $key, $val ) = @_;
			$key % 2 == 1;
		}
	),
	rh( 2 => 4, 5 => 6 ),
	'Testing reject()'
);

is_deeply(
	rh( 1 => 3, 2 => 4 )->rejectEx(
		sub {
			my ( $key, $val ) = @_;
			$key % 2 == 1;
		}
	),
	rh( 2 => 4 ),
	'Testing rejectEx()'
);

is(
	rh( 1 => 3, 2 => 4 )->rejectEx(
		sub {
			my ( $key, $val ) = @_;
			$key == 5;
		}
	),
	undef,
	'Testing rejectEx() with nothing changed'
);

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4, 5 => 6 )->reverse_each(
			sub {
				my ( $key, $val ) = @_;
				print "$key, $val, ";
			}
		);
	},
	'5, 6, 3, 4, 1, 2, ',
	'Testing reverse_each()'
);

my $rh = rh( 1 => 2 );
$rh->replace( { 3 => 4, 5 => 6 } );
is_deeply( $rh, { 3 => 4, 5 => 6 }, 'Testing replace()' );

is_deeply(
	rh( 'a' => 'b', 1 => 2, 'c' => 'd', 3 => '4' )->select(
		sub {
			my ( $key, $val ) = @_;
			looks_like_number($key) && looks_like_number($val);
		}
	),
	rh( 1 => 2, 3 => 4 ),
	'Testing select()'
);

my $rh = rh( 'a' => 'b', 1 => 2, 'c' => 'd', 3 => 4 );
$rh->selectEx(
	sub {
		my ( $key, $val ) = @_;
		looks_like_number($key) && looks_like_number($val);
	}
);
is_deeply( $rh, rh( 1 => 2, 3 => 4 ), 'Testing selectEx()' );

is_deeply( rh( 'a' => 'b', 1 => 2, 'c' => 'd', 3 => 4 )->selectEx( sub { 1 } ),
	undef, 'Testing selectEx() with nothing changed' );

my $rh = rh( 1 => 2 );
is_deeply( $rh->shift, ra( 1, 2 ), 'Testing shift()' );

is_deeply( $rh, rh, 'Testing after shift()' );

is_deeply( rh->shift, undef, 'Testing shift() with empty hash' );

is_deeply(
	rh( 'a' => 1, 'b' => 0, 'c' => 0, 'd' => 1 )->slice_before(
		sub {
			my ( $key, $val ) = @_;
			$val == 0;
		}
	),
	ra( [ [ 'a', 1 ] ], [ [ 'b', 0 ] ], [ [ 'c', 0 ], [ 'd', 1 ] ] ),
	'Testing slice_before()'
);

is_deeply(
	rh( 'a' => 1, 'b' => 0, 'c' => 0, 'd' => 1 )->slice_before(qr/^\[[a-z]/),
	ra( [ [ 'a', 1 ] ], [ [ 'b', 0 ] ], [ [ 'c', 0 ] ], [ [ 'd', 1 ] ] ),
	'Testing slice_before() with regex'
);

my $rh = rh( 1 => 2 );
is( $rh->store( 3, 4 ), 4, 'Testing store()' );

is_deeply( $rh, rh( 1 => 2, 3 => 4 ), 'Testing after store()' );

is_deeply(
	rh( 1 => 2, 3 => 4, 5 => 6 )->take(2),
	ra( [ 1, 2 ], [ 3, 4 ] ),
	'Testing take()'
);

dies_ok { rh( 1 => 2, 3 => 4, 5 => 6 )->take(-1) }
'Testing take() with negative array size';

is_deeply(
	rh( 1 => 2, 3 => 4, 5 => 6 )->take_while(
		sub {
			my ( $key, $val ) = @_;
			$key <= 3;
		}
	),
	ra( [ 1, 2 ], [ 3, 4 ] ),
	'Testing take_while()'
);

is_deeply(
	rh( 1 => 2, 'a' => 'b' )->to_a,
	ra( [ 1, 2 ], [ 'a', 'b' ] ),
	'Testing to_a()'
);

my $rh = rh;
is( $rh, $rh->to_h, 'Testing to_h()' );

is( rh( 1 => 2, 3 => 4 )->has_value(4), 1, 'Testing has_value()' );

is( rh( 1 => 2, 3 => 4 )->has_value(5),
	0, 'Testing has_value() with nonexist value' );

is(
	rh( 1 => 2, 3 => 4, 5 => 6 )->values_at( 3, 4, 6 ),
	[ 4, undef, undef ],
	'Testing values_at()'
);

is_deeply(
	rh( 1 => [ 2, 3 ], 4 => [ 5, 6 ], 7 => 8 )->zip( [ 9, 10 ] ),
	ra( [ [ 1, [ 2, 3 ] ], 9 ], [ [ 4, [ 5, 6 ] ], 10 ], [ [ 7, 8 ], undef ] ),
	'Testing zip()'
);
