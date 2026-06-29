use strict;
use warnings;

use Scalar::Util qw/blessed/;

use Test::More;

{
	package Stringy::Object;
	use overload '""' => sub { shift->$* }, fallback => 1;
	sub new {
		my ($pkg, $str) = @_;
		bless \(my $o = $str), $pkg;
	}
}


use constant::string 
	Stringy::Object->new( 'FOO' ),
	Stringy::Object->new( 'BAR' ),
	Stringy::Object->new( 'BAZ' );

ok( blessed FOO, 'constant FOO is a blessed reference' );
ok( blessed BAR, 'constant BAR is a blessed reference' );
ok( blessed BAZ, 'constant BAZ is a blessed reference' );

ok( FOO->isa("Stringy::Object") , 'constant FOO is a "Stringy::Object"' );
ok( BAR->isa("Stringy::Object") , 'constant BAR is a "Stringy::Object"' );
ok( BAZ->isa("Stringy::Object") , 'constant BAZ is a "Stringy::Object"' );

ok( FOO eq 'FOO', 'constant FOO is a constant with a string value of "FOO"' );
ok( BAR eq 'BAR', 'constant BAR is a constant with a string value of "BAR"' );
ok( BAZ eq 'BAZ', 'constant BAZ is a constant with a string value of "BAZ"' );


done_testing;
