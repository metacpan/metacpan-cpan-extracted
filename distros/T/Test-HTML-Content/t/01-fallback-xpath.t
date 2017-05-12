use strict;
use Test::More tests => 4;

my $HTML = "<html><body><a href='target'>dot</a></body></html>";

SKIP: {
  eval {
    require Test::Without::Module;
    Test::Without::Module->import( 'XML::LibXML' );
  };
  skip "Need Test::Without::Module to test the fallback", 4
    if $@;

  use_ok("Test::HTML::Content");
  link_ok($HTML,'target',"Finding a link works without XML::LibXML");
  my ($result,$args);
  eval {
    ($result,$args) = Test::HTML::Content::__count_tags($HTML,'a',{_content=>'dot'});
  };
  is($@,'',"Missing prerequisites don't let the tests fail");
  ok($result eq 'skip' || $result == 1,'Skipped or passed when XML::LibXML is missing')
    or diag "Expected 'skip' or '1', but got '$result'";
};
