use strict;
use Test::More tests => 4;

SKIP: {
  eval {
    require Test::Without::Module;
    Test::Without::Module->import( 'XML::XPath' );
    Test::Without::Module->import( 'XML::LibXML' );
  };
  skip "Need Test::Without::Module to test the fallback", 4
    if $@;

  use_ok("Test::HTML::Content");
  link_ok("<html><body><a href='here'>dot</a></body></html>",'here',"Finding a link works without xpath");
  my ($result,$args);
  eval {
    ($result,$args) = Test::HTML::Content::__count_tags("<html><body><a href='here'>dot</a></body></html>",'a',{_content=>'dot'});
  };
  is($@,'',"Missing prerequisites don't let the tests fail");
  is($result,'skip','Missing prerequisites make the tests skip instead');
};
