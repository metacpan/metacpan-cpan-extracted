use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


## Test 1
my $desc = "not ok 1 - Child has descendant";
test_out($desc);
test_fail(+2);
test_diag("Element a do not have any descendants for elem");
is_descendants("<a><p><c><d></d></c></p></a>", "elem", "Child has descendant"); #FAIL
test_test( "Negative Test Case - Child has descendant");

## Test 2
$desc = "ok 1 - Child has descendant";
test_out($desc);
is_descendants("<a><p><c><d></d></c></p></a>", "d", "Child has descendant"); #FAIL
test_test("Child has descendant");
