# Test script to test the failure modes of Test::HTML::Content
use Test::More;
BEGIN{
  eval {
    require Test::Builder::Tester;
    Test::Builder::Tester->import;
  };

  if ($@) {
    plan skip_all => "Test::Builder::Tester required for testing error messages";
  }
};

BEGIN {
  plan tests => 7;
  use_ok('Test::HTML::Content');
};

SKIP: {

if (! $Test::HTML::Content::can_xpath) {
  skip "Need XPath functionality to test it", 6;
  exit;
};

my $HTML = q{<html><head><title>Test</title></head>
<body>
<p foo="bar"></p>
<p foo="foo">1</p>
<p foo="baz">2</p>
</body>
</html>
};

test_out("not ok 1 - no XPath results found");
test_fail(+5);
test_diag(q{Got},
          q{  <p foo="bar"/>},
          q{  <p foo="foo">1</p>},
          q{  <p foo="baz">2</p>});
xpath_ok($HTML,'//p[@boo]','//p',"no XPath results found");
test_test("Finding no xpath results where some should be outputs the fallback");

test_out("not ok 1 - no XPath results found");
test_fail(+2);
test_diag(q{Got none});
xpath_ok($HTML,'//p[@boo]',"no XPath results found");
test_test("Finding no xpath results (implicit)");

test_out("not ok 1 - no XPath results found");
test_fail(+5);
test_diag(q{Got},
          q{  <p foo="bar"/>},
          q{  <p foo="foo">1</p>},
          q{  <p foo="baz">2</p>});
no_xpath($HTML,'//p[@foo]','//p',"no XPath results found");
test_test("Finding xpath results where none should be outputs the fallback");

test_out("not ok 1 - no XPath results found");
test_fail(+5);
test_diag(q{Got},
          q{  <p foo="bar"/>},
          q{  <p foo="foo">1</p>},
          q{  <p foo="baz">2</p>});
no_xpath($HTML,'//p',"no XPath results found");
test_test("Finding xpath results (implicit fallback)");

test_out("not ok 1 - no XPath results found");
test_fail(+5);
test_diag(q{Got},
          q{  <p foo="bar"/>},
          q{  <p foo="foo">1</p>},
          q{  <p foo="baz">2</p>});
xpath_count($HTML,'//p',4,"no XPath results found");
test_test("Too few hits get reported");

test_out("not ok 1 - no XPath results found");
test_fail(+5);
test_diag(q{Got},
          q{  <p foo="bar"/>},
          q{  <p foo="foo">1</p>},
          q{  <p foo="baz">2</p>});
xpath_count($HTML,'//p',2,"no XPath results found");
test_test("Too many hits get reported");

};