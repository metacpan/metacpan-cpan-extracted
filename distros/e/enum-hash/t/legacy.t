use strict;
use warnings;
use Test::More tests => 17;

BEGIN {
	use_ok('enum::hash', 'enum');
}


my %enum = enum (qw/
	:Months_=0 Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
	:Days_     Sun=0 Mon Tue Wed Thu Fri Sat
	:Letters_=0 A..Z
	:=0
	: A..Z
	Ten=10	Forty=40	FortyOne	FortyTwo
	Zero=0	One			Two			Three=3	Four
	:=100
/);


is( $enum{Months_Jan}, 0 );
is( $enum{Months_Dec}, 11 );

is( $enum{Days_Sun}, 0 );
is( $enum{Days_Sat}, 6 );

is( $enum{Letters_A}, 0 );
is( $enum{Letters_Z}, 25);

is( $enum{A}, 0 );
is( $enum{Z}, 25 );

is( $enum{Ten},      10 );
is( $enum{Forty},    40 );
is( $enum{FortyTwo}, 42 );

is( $enum{Zero},  0 );
is( $enum{One},   1 );
is( $enum{Two},   2 );
is( $enum{Three}, 3 );
is( $enum{Four},  4 );

