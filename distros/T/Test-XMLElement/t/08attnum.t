use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


## Test 1
my $desc = "ok 1 - N Number of Attributes";
test_out($desc);
number_of_attribs("<a murug='b' c='d' e='f'/>", 3, "N Number of Attributes"); #PASS
test_test("Element has N number of attributes");

  ## Test 2
$desc = "not ok 1 - N Number of Attributes";
test_out($desc);
test_fail(+2);
test_diag("         got: 3", "    expected: 2", "Element a have 3 attributes");
number_of_attribs("<a murug='b' c='d' e='f'/>", 2, "N Number of Attributes"); #FAIL
test_test("Negative Test Case - Element has N number of attributes");
