use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;

## Test 1
my $desc = "not ok 1 - Element 'a' contains child b";
test_out($desc);
test_fail(+2);
test_diag("Element 'a' do not have any child named b");
have_child_name("<a><c/></a>", "b", "Element 'a' contains child b");
test_test( "Negative Test Case - Element 'a' contains child 'b'");

## Test 2
$desc = "ok 1 - Element 'a' contains child b";
test_out($desc);
have_child_name("<a><b>Kanye West</b></a>", "b", "Element 'a' contains child b");
test_test("Element 'a' contains child b");
