use strict;
use warnings;
use Test::Builder::Tester tests => 10;
use Test::XMLElement;

my $xml = "<book><title>Kanye West</title>
                <section1><head>Biography</head>
		<p class='p1' font='arial' size='10'>Kanye Omari West is one of the <b>best hip-hop producer</b> and rapper</p>
		<p class='p1' font='helv' size='20'>Kanye Omari West is one of the <b>best hip-hop producer</b> and rapper</p>
		</section1>
                <section1><head>Biography</head>
		<p>None</p></section1>
	   </book>";


my $i=1;
## Test 1..6
my $desc = "ok 1 - XPath Entry";
my @xpath =(['//p',3],['/book/section1',2],['//p[@class]',2],['//section1//b',2],['//p[@font="arial"]',1],['//p[@class and @font]',2]);

foreach my $xpath (@xpath) {
  test_out($desc);
  is_xpath_count($xml, $xpath->[0],$xpath->[1], "XPath Entry"); #PASS
  test_test("Xpath Entry - $i");
  $i++
}


## Test 7
$desc = "not ok 1 - XPath Entry 1";
test_out($desc);
test_fail(+2);
test_diag("         got: 1", "    expected: 0", "XPath expression /a/b did not had same elements as required count 0");
is_xpath_count("<a><b/><c/><d/></a>", "/a/b", 0, "XPath Entry 1"); #FAIL
test_test( "Negative Test Case - XPath Entry 1");

#Test 8
$desc = "not ok 1 - XPath Entry 2";
test_out($desc);
test_fail(+2);
test_diag("         got: 2", "    expected: 1", "XPath expression /book/section1 did not had same elements as required count 1");
is_xpath_count($xml, "/book/section1", 1, "XPath Entry 2"); #FAIL
test_test( "Negative Test Case - XPath Entry 2");

#Test 9
$desc = "not ok 1 - XPath Entry 3";
test_out($desc);
test_fail(+2);
test_diag("Failed due to token // doesn't match format of a 'Step'");
is_xpath_count($xml, "////book/c", 1, "XPath Entry 3"); #FAIL
test_test( "Negative Test Case - XPath Entry 3");

#Test 10
$desc = "not ok 1 - XPath Entry 4";
test_out($desc);
test_fail(+2);
test_diag("         got: 3", "    expected: 2", "XPath expression //section1//p did not had same elements as required count 2");
is_xpath_count($xml, "//section1//p", 2, "XPath Entry 4"); #FAIL
test_test( "Negative Test Case - XPath Entry 4");