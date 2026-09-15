use strict;
use warnings;

use Scalar::Util qw/dualvar isdual/;

use Test::More;

use constant::string::ucfirst
	dualvar( 1, 'one'   ), 
	dualvar( 2, 'two'   ),
	dualvar( 3, 'three' );

ok( isdual( One   ), 'constant "One" is a dualvar' );
ok( isdual( Two   ), 'constant "Two" is a dualvar' );
ok( isdual( Three ), 'constant "Three" is a dualvar' );

ok( One   == 1, 'One is a constant with the numeric value 1' );
ok( Two   == 2, 'Two is a constant with the numeric value 2' );
ok( Three == 3, 'Three is a constant with the numeric value 3' );

ok( One   eq 'one',   'One is a constant with the string value "one"');
ok( Two   eq 'two',   'Two is a constant with the string value "two"' );
ok( Three eq 'three', 'Three is a constant with the string value "three"' );



done_testing;
