use strict;
use warnings;
use Test::More tests => 54;
use PDL;
use Test::PDL qw( eq_pdl_diag );
use Test::NoWarnings;

# remember that ok() forces scalar context on the condition it tests, the
# prototype being ok($;$)

my ( $got, $expected, $ok, $diag );

( $ok, $diag ) = eq_pdl_diag();
ok !$ok;
is $diag, 'received value is not a piddle';

$got = pdl( 9,-10 );
( $ok, $diag ) = eq_pdl_diag( $got );
ok !$ok;
is $diag, 'expected value is not a piddle';

$expected = 3;
$got = 4;
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'received value is not a piddle';

$expected = 3;
$got = long( 3,4 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'expected value is not a piddle';

$expected = short( 1,2 );
$got = -2;
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'received value is not a piddle';

Test::PDL::set_options( EQUAL_TYPES => 0 );
$expected = long( 3,4 );
$got = pdl( 3,4 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok $ok;

Test::PDL::set_options( EQUAL_TYPES => 1 );
$expected = long( 3,4 );
$got = pdl( 3,4 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
Test::PDL::set_options( EQUAL_TYPES => 0 );

$expected = long( 3 );
$got = long( 3,4 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'dimensions do not match in number';

$expected = zeroes( double, 3,4 );
$got = zeroes( double, 3,4,1 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'dimensions do not match in number';

$expected = long( [ [3,4],[1,2] ] );
$got = long( [ [3,4,5], [1,2,3] ] );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'dimensions do not match in extent';

$expected = long( 4,5,6,-1,8,9 )->inplace->setvaltobad( -1 );
$got = long( 4,5,6,7,-1,9 )->inplace->setvaltobad( -1 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'bad value patterns do not match';

$expected = long( 4,5,6,7,8,9 );
$got = long( 4,5,6,7,-8,9 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'values do not match';

$expected = pdl( 4,5,6,7,8,9 );
$got = pdl( 4,5,6,7,-8,9 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'values do not match';

$expected = pdl( 4,5,6,7,8,9 );
$got = pdl( 4,5,6,7,8.001,9 );
# remember that approx() remembers the tolerance across invocations, so we
# explicitly specify the tolerance at each invocation
ok !all( approx $got, $expected, 1e-6 ), 'differ by more than 0.000001';
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'values do not match';

$expected = pdl( 4,5,6,7,8,9 );
$got = pdl( 4,5,6,7,8.0000001,9 );
ok all( approx $got, $expected, 1e-6 ), 'differ by less than 0.000001';
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok $ok;

Test::PDL::set_options( TOLERANCE => 1e-2 );
$expected = pdl( 4,5,6,7,8,9 );
$got = pdl( 4,5,6,7,8.001,9 );
ok all( approx $got, $expected, 1e-2 ), 'differ by less than 0.01';
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok $ok;

$expected = pdl( 0,1,2,3,4 );
$got = sequence 5;
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok $ok;

$expected = null;
$got = null;
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok $ok;

$expected = null;
$got = pdl( 1,2,3 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'values do not match';

$expected = pdl( 1,2,3 );
$got = null;
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'values do not match';

note 'mixed-type comparisons';

$expected = double( 0,1,2.001,3,4 );
$got = long( 0,1,2,3,4 );

ok all( approx $got, $expected, 1e-2 ), 'differ by less than 0.01';
Test::PDL::set_options( TOLERANCE => 1e-2 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok $ok;

ok !all( approx $got, $expected, 1e-6 ), 'differ by more than 0.000001';
Test::PDL::set_options( TOLERANCE => 1e-6 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'values do not match';

$expected = short( 0,1,2,3,4 );
$got = float( 0,1,2.001,3,4 );

ok all( approx $got, $expected, 1e-2 ), 'differ by less than 0.01';
Test::PDL::set_options( TOLERANCE => 1e-2 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok $ok;

ok !all( approx $got, $expected, 1e-6 ), 'differ by more than 0.000001';
Test::PDL::set_options( TOLERANCE => 1e-6 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'values do not match';

$expected = float( 0,-1,2.001,3,49999.998 );
$got = double( 0,-0.9999,1.999,3,49999.999 );

ok all( approx $got, $expected, 1e-2 ), 'differ by less than 0.01';
Test::PDL::set_options( TOLERANCE => 1e-2 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok $ok;

ok !all( approx $got, $expected, 1e-6 ), 'differ by more than 0.000001';
Test::PDL::set_options( TOLERANCE => 1e-6 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok !$ok;
is $diag, 'values do not match';

note 'miscellaneous';

$expected = long( 4,5,6,7,8,9 );
$expected->badflag( 1 );
$got = long( 4,5,6,7,8,9 );
$got->badflag( 0 );
( $ok, $diag ) = eq_pdl_diag( $got, $expected );
ok $ok;
