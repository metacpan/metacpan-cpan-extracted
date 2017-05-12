BEGIN
	{
	@good_isbns = qw(
	0004133250
	0064443094
	014037499X
	0295974842
	1881508501
	188150851X
	382660704X
	3826606604
	);
	
	@bad_isbns = qw(
	1565922572
	abcdefghij
	156592
	);
	}
use Test::Builder::Tester tests => 14;
use Test::ISBN;

foreach my $isbn ( @good_isbns )
	{
	test_out( 'ok 1' );
	isbn_ok( $isbn );
	test_test("isbn_ok");
	}

foreach my $isbn ( @bad_isbns )
	{
	test_out( 'not ok 1' );
	isbn_ok( $isbn );
	test_diag(
		"The argument [$isbn] is not a valid ISBN",
		"    Failed test ($0 at line " . line_num(-1) . ")",
		);
	test_test("isbn_ok catching errors");
	}

test_out( 'ok 1', 'ok 2' );
isbn_group_ok( "1565927168", "1" );
isbn_publisher_ok( "1565927168", "56592" );
test_test("isbn_country_ok, isbn_publisher_ok");

test_out( 'not ok 1' );
isbn_group_ok( "1565927168", "0" );
test_diag(
	"ISBN [1565927168] group code is wrong", 
	"\tExpected [0]" , "\tGot [1]" ,
	"    Failed test ($0 at line " . line_num(-1) . ")",
	 );
test_test("isbn_country_ok");


test_out( 'not ok 1' );
isbn_publisher_ok( "1565927168", "5659" );
test_diag(
	"ISBN [1565927168] publisher code is wrong",
	"\tExpected [5659]", "\tGot [56592]",
	"    Failed test ($0 at line " . line_num(-1) . ")",
	);
test_test("isbn_publisher_ok");
