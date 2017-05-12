use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
	use_ok('enum::hash', 'enum');
}


my %enum = enum (qw/
	:minus=-5 5 4 3 2 1 
	: 0 1
/);


is( $enum{minus5}, -5 );
is( $enum{minus4}, -4 );
is( $enum{minus3}, -3 );
is( $enum{minus2}, -2 );
is( $enum{minus1}, -1 );

is( $enum{0}, 0 );
is( $enum{1}, 1 );

