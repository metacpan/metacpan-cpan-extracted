use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


## Test 1
my $desc = "ok 1 - Element is empty";
test_out($desc);
is_empty("<a/>", "Element is empty"); #PASS
test_test( "Element is empty");

## Test 2
$desc = "not ok 1 - Element is empty";
test_out($desc);
test_fail(+2);
test_diag("Element a is not empty");
is_empty("<a></a>", "Element is empty"); #FAIL
test_test("Negative Test Case - Element is empty");
