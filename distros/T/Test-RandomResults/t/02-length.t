use Test::Builder::Tester tests => 13;
use Test::More;

BEGIN {
use_ok( 'Test::RandomResults' );
}

my $desc;

# length_lt

$desc = "length of 123456789 less than 20";
test_out("ok 1 - $desc");
length_lt( "123456789", 20, $desc);
test_test( $desc );

$desc = "length of 123456789 not less than 5";
test_out("not ok 1 - $desc");
test_fail(+2);
test_diag( "        length of 123456789 not less than 5" );
length_lt( "123456789", 5, $desc);
test_test( $desc );

# length_le

$desc = "length of 123456789 less than or equal to 20";
test_out("ok 1 - $desc");
length_le( "123456789", 20, $desc);
test_test( $desc );

$desc = "length of 123456789 less than or equal to 9";
test_out("ok 1 - $desc");
length_le( "123456789", 9, $desc);
test_test( $desc );

$desc = "length of 123456789 not less than or equal to 5";
test_out("not ok 1 - $desc");
test_fail(+2);
test_diag( "        length of 123456789 not less than or equal to 5" );
length_le( "123456789", 5, $desc);
test_test( $desc );

#length_eq

$desc = "length of 123456789 equal to 9";
test_out("ok 1 - $desc");
length_eq( "123456789", 9, $desc);
test_test( $desc );

$desc = "length of 123456789 not equal to 10";
test_out("not ok 1 - $desc");
test_fail(+2);
test_diag( "        length of 123456789 not equal to 10" );
length_eq( "123456789", 10, $desc);
test_test( $desc );

# length_gt
$desc = "length of 123456789 greater than 5";
test_out("ok 1 - $desc");
length_gt( "123456789", 5, $desc);
test_test( $desc );

$desc = "length of 123456789 not greater than 20";
test_out("not ok 1 - $desc");
test_fail(+2);
test_diag( "        length of 123456789 not greater than 20" );
length_gt( "123456789", 20, $desc);
test_test( $desc );

# length_ge

$desc = "length of 123456789 greater than or equal to 5";
test_out("ok 1 - $desc");
length_ge( "123456789", 5, $desc);
test_test( $desc );

$desc = "length of 123456789 greater than or equal to 9";
test_out("ok 1 - $desc");
length_ge( "123456789", 9, $desc);
test_test( $desc );

$desc = "length of 123456789 not greater than or equal to 20";
test_out("not ok 1 - $desc");
test_fail(+2);
test_diag( "        length of 123456789 not greater than or equal to 20" );
length_ge( "123456789", 20, $desc);
test_test( $desc );
