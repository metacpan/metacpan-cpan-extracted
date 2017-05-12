use strict;
use warnings;
use Test::Builder::Tester tests => 15;
use Test::XMLElement;

my $xml = "<book><title>Kanye West</title>
                <section1><head>Biography</head>
		<p class='p1' font='arial' size='10'>Kanye Omari West is one of the <b>best hip-hop producer</b> and rapper</p>
		<p class='p1' font='helv' size='20'>Kanye Omari West is one of the <b>best hip-hop producer</b> and rapper</p>
		</section1>
                <section1><head>Biography</head>
		<p>None</p></section1>
		<BBB id='b1'/>
		<BBB id='b2'/>
		<BBB name=' bbb '/>
		<BBB/>
	   </book>";


my $i=1;
## Test 1..6
my $desc = "ok 1 - XPath Entry";
my @xpath =('//p','/book/section1','//p[@class]','//section1//b','//p[@font="arial"]','//p[@class and @font]','//BBB[@id]','//BBB[@name]','//BBB[not(@*)]','//BBB[normalize-space(@name) = "bbb"]','/descendant::*');

foreach my $xpath (@xpath) {
  test_out($desc);
  is_xpath($xml, $xpath, "XPath Entry"); #PASS
  test_test("Xpath Entry - $i");
  $i++
}


## Test 7
$desc = "not ok 1 - XPath Entry 1";
test_out($desc);
test_fail(+2);
test_diag("Element a do not have elements matching /a/b/c");
is_xpath("<a><b/><c/><d/></a>", "/a/b/c", "XPath Entry 1"); #FAIL
test_test( "Negative Test Case - XPath Entry 1");

#Test 8
$desc = "not ok 1 - XPath Entry 2";
test_out($desc);
test_fail(+2);
test_diag("Element book do not have elements matching /book/c");
is_xpath($xml, "/book/c", "XPath Entry 2"); #FAIL
test_test( "Negative Test Case - XPath Entry 2");

#Test 9
$desc = "not ok 1 - XPath Entry 3";
test_out($desc);
test_fail(+2);
test_diag("Failed due to token // doesn't match format of a 'Step'");
is_xpath($xml, "////book/c", "XPath Entry 3"); #FAIL
test_test( "Negative Test Case - XPath Entry 3");

#Test 10
$desc = "not ok 1 - XPath Entry 4";
test_out($desc);
test_fail(+2);
test_diag("Element book do not have elements matching section1//p");
is_xpath($xml, "section1//p", "XPath Entry 4"); #FAIL
test_test( "Negative Test Case - XPath Entry 4");