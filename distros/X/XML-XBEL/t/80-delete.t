use strict;
use Test::More;

plan tests => 11;

#

use_ok("XML::XBEL");

my $xbel = XML::XBEL->new();
isa_ok($xbel,"XML::XBEL");

#

ok($xbel->parse_file("./t/test.xbel"),
   "parsed xbel");

cmp_ok(scalar($xbel->bookmarks(1)),"==",41,
       "xbel has 41 bookmarks");

map { 
  $_->delete();
} $xbel->bookmarks(1);

cmp_ok(scalar($xbel->bookmarks(1)),"==",0,
       "xbel has 0 bookmarks");

#

ok($xbel->parse_file("./t/test.xbel"),
   "parsed xbel");

cmp_ok(scalar($xbel->folders(1)),"==",2,
      "xbel has 2 folders");

map { 
  $_->delete();
} $xbel->folders(1);

cmp_ok(scalar($xbel->folders(1)),"==",0,
       "file has 0 folders");

#

ok($xbel->parse_file("./t/test.xbel"),
   "parsed xbel");

cmp_ok(scalar($xbel->aliases()),"==",1,
       "xbel has 1 aliases");

map { 
  $_->delete();
} $xbel->aliases();

cmp_ok(scalar($xbel->aliases()),"==",0,
       "xbel has 0 aliases");

# $Id: 80-delete.t,v 1.3 2004/07/03 06:17:50 asc Exp $
