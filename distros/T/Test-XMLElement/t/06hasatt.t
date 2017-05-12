use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


## Test 1
my $desc = "ok 1 - Has Attributes";
test_out($desc);
has_attributes('<first name="kanye" pro="producer">Kanye</first>', "Has Attributes"); #PASS
test_test( "Element has attributes");

## Test 2
$desc = "not ok 1 - Has Attributes";
test_out($desc);
test_fail(+2);
test_diag("Element a dont have attributes");
has_attributes("<a></a>", "Has Attributes"); #FAIL
test_test("Negative Test Case - Element has attributes");
