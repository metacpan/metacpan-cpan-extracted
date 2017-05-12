# Test script to test the failure modes of Test::HTML::Content
use Test::More;

eval {
  require Test::Builder::Tester;
  Test::Builder::Tester->import;
};

if ($@) {
  plan skip_all => "Test::Builder::Tester required for testing error messages";
}

plan tests => 1+1*2;

use_ok('Test::HTML::Content');

# Test that each exported function fails as documented

sub run_tests {
  test_out("not ok 1 - Text failure (empty document)");
  test_fail(+1);
  text_ok("","Perl","Text failure (empty document)");

  no warnings 'once';
  if ($Test::HTML::Content::can_xpath) {
    test_diag( 'Invalid HTML:', "" );
  } else {
    test_diag( 'No text found at all', "Expected at least one text element like 'Perl'" );
  };

  test_test("Empty document gets reported");
};

run_tests;
require Test::HTML::Content::NoXPath;
Test::HTML::Content::NoXPath->install;
run_tests;