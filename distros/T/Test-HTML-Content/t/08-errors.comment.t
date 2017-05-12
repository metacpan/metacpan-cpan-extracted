# Test script to test the failure modes of Test::HTML::Content
use Test::More;
use lib 't';
use testlib;
use vars qw( $Test::HTML::Content::can_xpath );

eval {
  require Test::Builder::Tester;
  Test::Builder::Tester->import;
};

if ($@) {
  plan skip_all => "Test::Builder::Tester required for testing error messages";
}

# perldelta 5.14
# Accept both old and new-style stringification
my $modifiers = (qr/foobar/ =~ /\Q(?^/) ? "^" : "-xism";

sub run {
 # Test that each exported function fails as documented

 test_out("not ok 1 - Comment failure (no comments)");
 test_fail(+7);
   if ($Test::HTML::Content::can_xpath eq 'XML::LibXML') {
     test_diag("Invalid HTML:","");
   } else {
     test_diag("No comment found at all",
               "Expected at least one comment like 'hidden message'",);
   };
 comment_ok("","hidden message","Comment failure (no comments)");
 test_test("Finding no comment works");

 test_out("not ok 1 - Comment failure (nonmatching comments)");
 test_fail(+9);
   #if ($Test::HTML::Content::can_xpath eq 'XML::XPath') {
   #  test_diag("Invalid HTML:","<!-- hidden massage --><!-- hidden massage --><!-- hidden massage -->");
   #} else {
     test_diag("Saw '<!-- hidden massage -->'",
               "Saw '<!-- hidden massage -->'",
               "Saw '<!-- hidden massage -->'",
               "Expected at least one comment like 'hidden message'");
   #};
 comment_ok("<!-- hidden massage --><!-- hidden massage --><!-- hidden massage -->",
         "hidden message","Comment failure (nonmatching comments)");
 test_test("Finding no comment returns all other comments");

 test_out("not ok 1 - Comment failure (two comments that shouldn't exist do)");
 test_fail(+8);
   #if ($Test::HTML::Content::can_xpath eq 'XML::XPath') {
   #  test_diag("Invalid HTML:","<!-- hidden massage --><!-- hidden massage -->");
   #} else {
     test_diag("Saw '<!-- hidden massage -->'",
               "Saw '<!-- hidden massage -->'",
               "Expected no comment like '(?$modifiers:hidden m.ssage)'");
   #};
 no_comment("<!-- hidden massage --><!-- hidden massage -->",
         qr"hidden m.ssage","Comment failure (two comments that shouldn't exist do)");
 test_test("Finding a comment where none should be returns all comments");

 test_out("not ok 1 - Comment failure (too few comments)");
 test_fail(+8);
   #if ($Test::HTML::Content::can_xpath eq 'XML::XPath') {
   #  test_diag("Invalid HTML:","<!-- hidden massage --><!-- hidden massage -->");
   #} else {
     test_diag("Saw '<!-- hidden massage -->'",
               "Saw '<!-- hidden massage -->'",
               "Expected exactly 3 comments like '(?$modifiers:hidden m.ssage)'");
   #};
 comment_count("<!-- hidden massage --><!-- hidden massage -->",
         qr"hidden m.ssage",3,"Comment failure (too few comments)");
 test_test("Diagnosing too few comments works");

 test_out("not ok 1 - Comment failure (too few comments)");
 test_fail(+8);
   #if ($Test::HTML::Content::can_xpath eq 'XML::XPath') {
   #  test_diag("Invalid HTML:","<!-- hidden massage --><!-- hidden massage -->");
   #} else {
     test_diag("Saw '<!-- hidden massage -->'",
               "Saw '<!-- hidden massage -->'",
               "Expected exactly 1 comments like '(?$modifiers:hidden m.ssage)'");
   #};
 comment_count("<!-- hidden massage --><!-- hidden massage -->",
         qr"hidden m.ssage",1,"Comment failure (too few comments)");
 test_test("Diagnosing too many comments works");
};

runtests( 5, \&run );
