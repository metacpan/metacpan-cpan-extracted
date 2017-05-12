use Test::Builder::Tester tests => 3;
use Test::More;

BEGIN {
use_ok( 'Test::RandomResults' );
}

my $desc;

$desc = "simple test";
test_out("ok 1 - $desc");
is_in( 1, [ 1, 2, 3 ], $desc);
test_test( $desc );

$desc = 'simple test to fail';
test_out( "not ok 1 - $desc" );
test_fail(+2);
test_diag( "        1 is not in (0 2 3)" );
is_in( 1, [ 0, 2, 3 ], $desc);
test_test( $desc );
