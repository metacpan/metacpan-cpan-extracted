use strict;
use warnings;
use Test::Builder::Tester tests => 2;
use Test::XMLElement;


my $xml;

## Test 1
my $desc = "not ok 1 - Element contains N children";
$xml = "<first><second>1</second><third>1</third><fourth>4</fourth></first>";
test_out($desc);
test_fail(+2);
test_diag("         got: 3", "    expected: 1", "Element 'first' do not have 1 children");
child_count_is($xml, 1, "Element contains N children"); #FAIL
test_test( "Negative Test Case - Element contains N children");

## Test 2 
$desc = "ok 1 - Element contains N children";
$xml = "<first><second>1</second>Kanye west is the best <p>producer</p> of all time</first>";
test_out($desc);
child_count_is($xml, 2, "Element contains N children"); #PASS
test_test( "Element contains N children");
