use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


## Test 1
my $desc = "not ok 1 - Attribute Name";
test_out($desc);
test_fail(+2);
test_diag("Element 'a' do not have any attribute named b");
attrib_name("<a murug='b' c='d' e='f'/>", "b", "Attribute Name");
test_test( "Negative Test Case - Attribute Name");

## Test 2
$desc = "ok 1 - Attribute Name";
test_out($desc);
attrib_name("<a murug='b' c='d' e='f'/>", "c", "Attribute Name");
test_test("Attribute Name");
