use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


my $xml;

## Test 1
my $desc = "not ok 1 - Has No Attributes";
test_out($desc);
test_fail(+2);
test_diag("Element a have attributes");
has_no_attrib("<a muru='k'></a>", "Has No Attributes"); #FAIL
test_test("Negative Test Case - Element has no attributes");

## Test 2
$desc = "ok 1 - Has No Attributes";
$xml = "<first><second>1</second><third>1</third><fourth>4</fourth></first>";
test_out($desc);
has_no_attrib($xml, "Has No Attributes"); #PASS
test_test("Element has no attributes");
