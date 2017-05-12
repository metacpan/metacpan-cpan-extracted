use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


## Test 1
my $desc = "not ok 1 - All Children";
test_out($desc);
test_fail(+2);
test_diag("         got: 1", "    expected: 3", "Element 'a' do not have all child named b");
all_children_are("<a><b/><c/><d/></a>", "b", "All Children"); #FAIL
test_test( "Negative Test Case - All Children");

## Test 2
$desc = "ok 1 - All Children";
test_out($desc);
all_children_are("<a><b/><b/><b/></a>", "b", "All Children"); #PASS
test_test("All Children");
