use strict;
use Test::More tests => 4;

SKIP: {
  eval {
    require Test::Without::Module;
    Test::Without::Module->import( 'XML::XPath' );
  };
  skip "Need Test::Without::Module to test the fallback", 4
    if $@;

  use_ok("Test::HTML::Content");
  link_ok("<html><body><a href='here'>dot</a></body></html>",'here',"Finding a link works without libxml");
  my ($result,$args);
  eval { ($result,$args) = Test::HTML::Content::__count_tags("<html><body><a href='here'>dot</a></body></html>",'a',{_content=>'dot'}); };
  is($@,'',"Missing prerequisites don't let the tests fail");
  ok($result eq 'skip' || $result == 1,'Skipped or passed when XML::XPath is missing')
    or diag "Expected 'skip' or '1', but got '$result'";
};
