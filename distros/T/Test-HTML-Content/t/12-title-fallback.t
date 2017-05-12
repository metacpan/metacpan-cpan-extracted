use strict;
use Test::More tests => 1+6*2;

BEGIN {
  use_ok( "Test::HTML::Content");

  if ($Test::HTML::Content::can_xpath) {
    require Test::HTML::Content::NoXPath;
    &Test::HTML::Content::NoXPath::install;
  };
};

eval {
  title_ok('<html><head><title>A test title</title></head><body></body></html>',qr"A test title","Title RE");
};
is( $@, "", "Gracefull title fallback (title_ok)" );

eval {
  title_ok('<html><head><title>A test title</title></head><body></body></html>',qr"^A test title$","Anchored title RE");
};
is( $@, "", "Gracefull title fallback (title_ok)" );

eval {
  title_ok('<html><head><title>A test title</title></head><body></body></html>',qr"test","Title RE works for partial matches");
};
is( $@, "", "Gracefull title fallback (title_ok)" );

eval {
  title_ok('<html><head><title>A test title</title></head><body></body></html>',"A test title","Title string");
};
is( $@, "", "Gracefull title fallback (title_ok)" );

eval {
  no_title('<html><head><title>A test title</title></head><body></body></html>',"test","Complete title string gets compared");
};
is( $@, "", "Gracefull title fallback (no_title)" );

eval {
  no_title('<html><head><title>A test title</title></head><body></body></html>',"A toast title","no_title string");
};
is( $@, "", "Gracefull title fallback (no_title)" );
