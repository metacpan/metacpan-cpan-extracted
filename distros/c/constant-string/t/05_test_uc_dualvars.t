use strict;
use warnings;

use Scalar::Util qw/dualvar isdual/;

use Test::More;

use constant::string::uc 
	dualvar( 1, 'One'   ), 
	dualvar( 2, 'Two'   ),
	dualvar( 3, 'Three' );

ok( isdual( ONE   ), 'constant "ONE" is a dualvar' );
ok( isdual( TWO   ), 'constant "TWO" is a dualvar' );
ok( isdual( THREE ), 'constant "THREE" is a dualvar' );

ok( ONE   == 1, 'ONE is a constant with the numeric value 1' );
ok( TWO   == 2, 'TWO is a constant with the numeric value 2' );
ok( THREE == 3, 'THREE is a constant with the numeric value 3' );

ok( ONE   eq 'One',   'ONE is a constant with the string value "One"');
ok( TWO   eq 'Two',   'TWO is a constant with the string value "Two"' );
ok( THREE eq 'Three', 'THREEE is a constant with the string value "Three"' );



done_testing;
