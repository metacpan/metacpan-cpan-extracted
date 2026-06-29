use strict;
use warnings;

use Scalar::Util qw/dualvar isdual/;

use Test::More;

use constant::string 
	dualvar( 1, 'ONE'   ), 
	dualvar( 2, 'TWO'   ),
	dualvar( 3, 'THREE' );

ok( isdual( ONE   ), 'constant "ONE" is a dualvar' );
ok( isdual( TWO   ), 'constant "TWO" is a dualvar' );
ok( isdual( THREE ), 'constant "THREE" is a dualvar' );

ok( ONE   == 1, 'ONE is a constant with the numeric value 1' );
ok( TWO   == 2, 'TWO is a constant with the numeric value 2' );
ok( THREE == 3, 'THREE is a constant with the numeric value 3' );

ok( ONE   eq 'ONE',   'ONE is a constant with the string value "ONE"');
ok( TWO   eq 'TWO',   'TWO is a constant with the string value "TWO"' );
ok( THREE eq 'THREE', 'THREEE is a constant with the string value "THREE"' );



done_testing;
