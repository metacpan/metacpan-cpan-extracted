# Test script to test the failure modes of Test::HTML::Content
use Test::More;

eval {
  require Test::Builder::Tester;
  Test::Builder::Tester->import;
};

if ($@) {
  plan skip_all => "Test::Builder::Tester required for testing error messages";
}

plan tests => 1;

use_ok('Test::HTML::Content');

# Test that doctype_ok fails as documented

# to be done