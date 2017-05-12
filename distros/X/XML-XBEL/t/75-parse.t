use strict;
use Test::More;

plan tests => 12;

use_ok("XML::XBEL");

my $xbel = XML::XBEL->new();
isa_ok($xbel,"XML::XBEL");

ok($xbel->parse_file("./t/test.xbel"),
   "parsed xbel");

cmp_ok($xbel->title(),"eq","Bookmarks",
       sprintf("xbel's title is %s",$xbel->title()));

#

cmp_ok(scalar($xbel->bookmarks()),"==",0,
       "xbel has 0 bookmarks");

cmp_ok(scalar($xbel->folders()),"==",1,
      "xbel has 1 folders");

cmp_ok(scalar($xbel->aliases()),"==",1,
       "xbel has 1 aliases");

#

cmp_ok(scalar($xbel->bookmarks(1)),"==",41,
       "xbel has 41 bookmarks");

my @folders = $xbel->folders(1);

cmp_ok(scalar(@folders),"==",2,
      "xbel has 2 folders");

cmp_ok(scalar($folders[0]->folders()),"==",1,
      "first folder has 1 sub folder");
      
cmp_ok(scalar($folders[1]->folders()),"==",0,
       "second folder has 0 sub folders");

cmp_ok(scalar($xbel->aliases(1)),"==",1,
       "xbel has 1 aliases");

# $Id: 75-parse.t,v 1.3 2004/06/24 02:15:15 asc Exp $
