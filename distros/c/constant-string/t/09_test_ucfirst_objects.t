use strict;
use warnings;

use Scalar::Util qw/blessed/;

use Test::More;

{
	package Stringy::Object;
	use overload '""' => sub { ${ shift() } }, fallback => 1;
	sub new {
		my ($pkg, $str) = @_;
		bless \(my $o = $str), $pkg;
	}
}


use constant::string::ucfirst
	Stringy::Object->new( 'Foo' ),
	Stringy::Object->new( 'bar' ),
	Stringy::Object->new( 'BAZ' );

ok( blessed Foo, 'constant Foo is a blessed reference' );
ok( blessed Bar, 'constant Bar is a blessed reference' );
ok( blessed BAZ, 'constant BAZ is a blessed reference' );

ok( Foo->isa("Stringy::Object") , 'constant Foo is a "Stringy::Object"' );
ok( Bar->isa("Stringy::Object") , 'constant Bar is a "Stringy::Object"' );
ok( BAZ->isa("Stringy::Object") , 'constant BAZ is a "Stringy::Object"' );

ok( Foo eq 'Foo', 'constant Foo is a constant with a string value of "Foo"' );
ok( Bar eq 'bar', 'constant Bar is a constant with a string value of "bar"' );
ok( BAZ eq 'BAZ', 'constant BAZ is a constant with a string value of "BAZ"' );


done_testing;
