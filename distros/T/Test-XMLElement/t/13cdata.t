use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


## Test 1
my $desc = "not ok 1 - Child has cdata";
test_out($desc);
test_fail(+2);
test_diag("Element a do not have any CDATA");
child_has_cdata("<a><b/><c/><d/></a>", "Child has cdata"); #FAIL
test_test( "Negative Test Case - Child has cdata");

## Test 2
$desc = "ok 1 - Child has cdata";
test_out($desc);
child_has_cdata("<a><![CDATA[foo < bar]]></a>", "Child has cdata"); #PASS
test_test("Child has cdata");
