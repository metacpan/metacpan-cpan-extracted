use strict;
use warnings;
use Test::More tests => 37;
use PDL;
use Test::PDL qw( eq_pdl );
use Test::NoWarnings;

my ( $got, $expected );

$got = pdl( 9,-10 );
ok !eq_pdl(), 'rejects missing arguments';
ok !eq_pdl( $got ), 'rejects missing arguments';

$expected = 3;
$got = 4;
ok !eq_pdl( $got, $expected ), 'rejects non-piddle arguments';

$expected = 3;
$got = long( 3,4 );
ok !eq_pdl( $got, $expected ), 'rejects non-piddle arguments';

$expected = short( 1,2 );
$got = -2;
ok !eq_pdl( $got, $expected ), 'rejects non-piddle arguments';

Test::PDL::set_options( EQUAL_TYPES => 0 );
$expected = long( 3,4 );
$got = pdl( 3,4 );
ok eq_pdl( $got, $expected ), 'all else being equal, compares equal on differing types when EQUAL_TYPES is false';

Test::PDL::set_options( EQUAL_TYPES => 1 );
$expected = long( 3,4 );
$got = pdl( 3,4 );
ok !eq_pdl( $got, $expected ), 'catches type mismatch, but only when EQUAL_TYPES is true';
Test::PDL::set_options( EQUAL_TYPES => 0 );

$expected = long( 3 );
$got = long( 3,4 );
ok !eq_pdl( $got, $expected ), 'catches dimensions mismatches (number of dimensions)';

$expected = zeroes( double, 3,4 );
$got = zeroes( double, 3,4,1 );
ok !eq_pdl( $got, $expected ), 'does not treat degenerate dimensions specially';

$expected = long( [ [3,4],[1,2] ] );
$got = long( [ [3,4,5], [1,2,3] ] );
ok !eq_pdl( $got, $expected ), 'catches dimensions mismatches (extent of dimensions)';

$expected = long( 4,5,6,-1,8,9 )->inplace->setvaltobad( -1 );
$got = long( 4,5,6,7,-1,9 )->inplace->setvaltobad( -1 );
ok !eq_pdl( $got, $expected ), 'catches bad value pattern mismatch';

$expected = long( 4,5,6,7,8,9 );
$got = long( 4,5,6,7,-8,9 );
ok !eq_pdl( $got, $expected ), 'catches value mismatches for integer data';

$expected = pdl( 4,5,6,7,8,9 );
$got = pdl( 4,5,6,7,-8,9 );
ok !eq_pdl( $got, $expected ), 'catches value mismatches for floating-point data';

$expected = pdl( 4,5,6,7,8,9 );
$got = pdl( 4,5,6,7,8.001,9 );
# remember that approx() remembers the tolerance across invocations, so we
# explicitly specify the tolerance at each invocation
ok !all( approx $got, $expected, 1e-6 ), 'differ by more than 0.000001';
ok !eq_pdl( $got, $expected ), 'approximate comparison for floating-point data fails correctly at documented default tolerance of 1e-6';

$expected = pdl( 4,5,6,7,8,9 );
$got = pdl( 4,5,6,7,8.0000001,9 );
ok all( approx $got, $expected, 1e-6 ), 'differ by less than 0.000001';
ok eq_pdl( $got, $expected ), 'approximate comparison for floating-point data succeeds correctly at documented default tolerance of 1e-6';

Test::PDL::set_options( TOLERANCE => 1e-2 );
$expected = pdl( 4,5,6,7,8,9 );
$got = pdl( 4,5,6,7,8.001,9 );
ok all( approx $got, $expected, 1e-2 ), 'differ by less than 0.01';
ok eq_pdl( $got, $expected ), 'approximate comparison for floating-point data succeeds correctly at user-specified tolerance of 1e-2';

$expected = pdl( 0,1,2,3,4 );
$got = sequence 5;
ok eq_pdl( $got, $expected ), 'succeeds when it should succeed';

$expected = null;
$got = null;
ok eq_pdl( $got, $expected ), 'null == null';

$expected = null;
$got = pdl( 1,2,3 );
ok !eq_pdl( $got, $expected ), 'pdl( ... ) != null';

$expected = pdl( 1,2,3 );
$got = null;
ok !eq_pdl( $got, $expected ), 'null != pdl( ... )';

note 'mixed-type comparisons';

$expected = double( 0,1,2.001,3,4 );
$got = long( 0,1,2,3,4 );

ok all( approx $got, $expected, 1e-2 ), 'differ by less than 0.01';
Test::PDL::set_options( TOLERANCE => 1e-2 );
ok eq_pdl( $got, $expected ), 'succeeds correctly for long/double';

ok !all( approx $got, $expected, 1e-6 ), 'differ by more than 0.000001';
Test::PDL::set_options( TOLERANCE => 1e-6 );
ok !eq_pdl( $got, $expected ), 'fails correctly for long/double';

$expected = short( 0,1,2,3,4 );
$got = float( 0,1,2.001,3,4 );

ok all( approx $got, $expected, 1e-2 ), 'differ by less than 0.01';
Test::PDL::set_options( TOLERANCE => 1e-2 );
ok eq_pdl( $got, $expected ), 'succeeds correctly for float/short';

ok !all( approx $got, $expected, 1e-6 ), 'differ by more than 0.000001';
Test::PDL::set_options( TOLERANCE => 1e-6 );
ok !eq_pdl( $got, $expected ), 'fails correctly for float/short';

$expected = float( 0,-1,2.001,3,49999.998 );
$got = double( 0,-0.9999,1.999,3,49999.999 );

ok all( approx $got, $expected, 1e-2 ), 'differ by less than 0.01';
Test::PDL::set_options( TOLERANCE => 1e-2 );
ok eq_pdl( $got, $expected ), 'succeeds correctly for double/float';

ok !all( approx $got, $expected, 1e-6 ), 'differ by more than 0.000001';
Test::PDL::set_options( TOLERANCE => 1e-6 );
ok !eq_pdl( $got, $expected ), 'fails correctly for double/float';

note 'miscellaneous';

$expected = long( 4,5,6,7,8,9 );
$expected->badflag( 1 );
$got = long( 4,5,6,7,8,9 );
$got->badflag( 0 );
ok eq_pdl( $got, $expected ), "isn't fooled by differing badflags";
