use Test::Builder::Tester tests => 6;
use Test::More;

use_ok( 'Test::URI' );


{
my $uri_string = "http://www.example.com/index.html#test";

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
test_out( "ok 1" );
uri_fragment_ok( $uri_string, 'test' );
test_test("uri_fragment_ok with string");


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
test_out( "not ok 1" );
uri_fragment_ok( $uri_string, 'buster' );
#test_diag("    Failed test ($0 at line " . line_num(-1) . ")",
#	"URI [$uri_string] does not have the right fragment",
#	"\tExpected [buster]",
#	"\tGot [test]");
test_test( 
	title    => "uri_fragment_ok with wrong string",
	skip_err => 1,
	);


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $uri_object = URI->new( $uri_string );
isa_ok( $uri_object, 'URI' );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
test_out( "ok 1" );
uri_fragment_ok( $uri_object, 'test' );
test_test( "uri_fragment_ok with objects");


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
test_out( "not ok 1" );
uri_fragment_ok( $uri_object, 'buster' );
#test_diag("    Failed test ($0 at line " . line_num(-1) . ")",
#	"URI [$uri_string] does not have the right fragment",
#	"\tExpected [buster]",
#	"\tGot [test]");
test_test( 
	title    => "uri_fragment_ok with wrong object",
	skip_err => 1,
	);

}
