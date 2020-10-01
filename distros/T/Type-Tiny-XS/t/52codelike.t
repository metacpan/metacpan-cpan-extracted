use strict;
use warnings;
use Test::More;

use_ok('Type::Tiny::XS');

{
	package Local::Overload;
	use overload q(&{}) => sub { sub { 42 } };
}

{
	package Local::Overload2;
	my %xyz = ( foo => 42 );
	use overload q(%{}) => sub { \%xyz };
}

my $obj = bless {}, 'Local::Overload';
is( $obj->(), 42 );

my $obj2 = bless [], 'Local::Overload2';
is( $obj2->{foo}, 42 );

ok Type::Tiny::XS::CodeLike(sub {}), 'sub {}';
ok Type::Tiny::XS::CodeLike(sub () {}), 'sub () {}';
ok Type::Tiny::XS::CodeLike($obj), '$obj';
ok !Type::Tiny::XS::CodeLike($obj2), 'NOT $obj2';
ok !Type::Tiny::XS::CodeLike({}), 'NOT {}';
ok !Type::Tiny::XS::CodeLike(1), 'NOT 1';

done_testing;
