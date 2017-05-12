use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


## Test 1
my $desc = "not ok 1 - Attribute Name and Value";
test_out($desc);
test_fail(+2);
test_diag("         got: 'd'", "    expected: 'e'", "Element 'a' do not have any attribute named c");
attrib_value("<a murug='b' c='d' e='f'/>", "c", "e", "Attribute Name and Value"); #FAIL
test_test( "Negative Test Case - Attribute Name and Value");

## Test 2
$desc = "ok 1 - Attribute Name and Value";
test_out($desc);
attrib_value("<a murug='b' c='d' e='f'/>", "c", "d", "Attribute Name and Value"); #PASS
test_test("Attribute Name and Value");
