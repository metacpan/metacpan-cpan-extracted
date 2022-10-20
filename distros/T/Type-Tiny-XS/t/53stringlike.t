use strict;
use warnings;
use Test::More;

use_ok('Type::Tiny::XS');

{
	package Local::Overload;
	use overload q("") => sub { "foo" };
}

{
	package Local::Overload2;
	my %xyz = ( foo => 42 );
	use overload q(%{}) => sub { \%xyz };
}

my $obj = bless {}, 'Local::Overload';
is( "$obj", 'foo' );

my $obj2 = bless [], 'Local::Overload2';
is( $obj2->{foo}, 42 );

ok Type::Tiny::XS::StringLike(""), '""';
ok Type::Tiny::XS::StringLike("123"), '"123"';
ok Type::Tiny::XS::StringLike($obj), '$obj';
ok !Type::Tiny::XS::StringLike($obj2), 'NOT $obj2';
ok !Type::Tiny::XS::StringLike({}), 'NOT {}';

my $arrayof = Type::Tiny::XS::get_coderef_for('ArrayRef[StringLike]');
ok $arrayof->( [ "", "123", $obj ] ), '$arrayof : 1';
ok !$arrayof->( [ "", "123", $obj, $obj2 ]), '$arrayof : 2';

done_testing;
