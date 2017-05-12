use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


## Test 1
my $desc = "not ok 1 - Nth Child Name";
test_out($desc);
test_fail(+2);
test_diag("         got: 'b'", "    expected: 'c'", "Element 'a' do not have 0 child named c");
nth_child_name("<a><b/><c/><d/></a>", 1, "c", "Nth Child Name"); #FAIL
test_test( "Negative Test Case - Nth Child Name");

## Test 2
$desc = "ok 1 - Nth Child Name";
test_out($desc);
nth_child_name("<a><b/><c/><d/></a>", 1, "b", "Nth Child Name"); #PASS
test_test("Nth Child Name");
