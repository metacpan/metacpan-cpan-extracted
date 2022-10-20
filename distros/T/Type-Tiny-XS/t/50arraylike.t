use strict;
use warnings;
use Test::More;

use_ok('Type::Tiny::XS');

{
	package Local::Overload;
	my @xyz = (1 .. 10);
	use overload q(@{}) => sub { \@xyz };
}

{
	package Local::Overload2;
	my %xyz = ( foo => 42 );
	use overload q(%{}) => sub { \%xyz };
}

{
	package Local::Overload3;
	my @xyz = (1 .. 10, 'bar');
	use overload q(@{}) => sub { \@xyz };
}


my $obj = bless {}, 'Local::Overload';
is( $obj->[1], 2 );

my $obj2 = bless [], 'Local::Overload2';
is( $obj2->{foo}, 42 );

ok Type::Tiny::XS::ArrayLike([]), '[]';
ok Type::Tiny::XS::ArrayLike([1..3]), '[1..3]';
ok Type::Tiny::XS::ArrayLike($obj), '$obj';
ok !Type::Tiny::XS::ArrayLike($obj2), 'NOT $obj2';
ok !Type::Tiny::XS::ArrayLike({}), 'NOT {}';
ok !Type::Tiny::XS::ArrayLike(1), 'NOT 1';

my $arrayof = Type::Tiny::XS::get_coderef_for('ArrayRef[ArrayLike]');
ok $arrayof->( [ [], [1..3], $obj ] ), '$arrayof : 1';
ok !$arrayof->( [ [], [1..3], $obj, $obj2 ]), '$arrayof : 2';

if ( $] ge 5.010000 ) {
	my $arraylikeof = Type::Tiny::XS::get_coderef_for('ArrayLike[Num]');
	ok(   $arraylikeof->( [ 1..4 ] ) );
	ok( ! $arraylikeof->( [ 1..4, 'foo' ] ) );
	ok(   $arraylikeof->( $obj ) );
	ok( ! $arraylikeof->( bless {}, 'Local::Overload3' ) );
	ok( ! $arraylikeof->( $obj2 ) );
}

done_testing;
