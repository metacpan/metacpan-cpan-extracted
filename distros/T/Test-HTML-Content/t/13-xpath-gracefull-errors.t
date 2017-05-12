# Test script to test the failure modes of Test::HTML::Content
use Test::More;
use lib 't';
use testlib;

eval {
  require Test::Builder::Tester;
  Test::Builder::Tester->import;
};

if ($@) {
  plan skip_all => "Test::Builder::Tester required for testing error messages";
}

sub run {
  use_ok('Test::HTML::Content');

  SKIP: {
    { no warnings 'once';
      $Test::HTML::Content::can_xpath
        or skip "XML::XPath or XML::LibXML required", 2;
    };

    my ($tree,$result,$seen);

    eval {
      ($result,$seen) = Test::HTML::Content::__count_comments("<!-- hidden massage --><!-- hidden massage --><!-- hidden massage -->", "hidden message");
    };
    is($@,'',"Invalid HTML does not crash the test");
    eval {
      ($tree) = Test::HTML::Content::__get_node_tree("<!-- hidden massage --><!-- hidden massage --><!-- hidden massage -->",'//comment()');
    };
    is($@,'',"Invalid HTML does not crash the test");
    # is($tree,undef,"The result of __get_node_tree is undef");
  }
};

runtests( 3, \&run);