use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


## Test 1
my $desc = 'ok 1 - Element a have children';
test_out( $desc );
have_child("<a><b/></a>", "Element a have children"); #PASS
test_test( "Element a have Children" );

## Test 2
$desc = "not ok 1 - Element a have children";
test_out($desc);
test_fail(+2);
test_diag("Element a do not have any children");
have_child("<a></a>", "Element a have children");
test_test( 'Negative Test Case - Element a have children' );
