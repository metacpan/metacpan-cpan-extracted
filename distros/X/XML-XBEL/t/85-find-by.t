use strict;
use Test::More;

plan tests => 9;

#

use_ok("XML::XBEL");

my $xbel = XML::XBEL->new();
isa_ok($xbel,"XML::XBEL");

ok($xbel->parse_file("./t/test.xbel"),
   "parsed xbel");

my $bm = $xbel->find_by_id("rdf%3A#\$u9UIH");
isa_ok($bm,"XML::XBEL::Bookmark");

cmp_ok($bm->title(),"eq","The processed book",
       "The processed book");

my $folder = $xbel->find_by_id("rdf%3A#\$khJ4y");
isa_ok($folder,"XML::XBEL::Folder");

cmp_ok($folder->title(),"eq","perl",
       "perl");

my $link = ($xbel->find_by_href("http://www.w3.org/2003/01/21-RDF-RDB-access/"))[0];
isa_ok($link,"XML::XBEL::Bookmark");

cmp_ok($link->title(),"eq","RDF Access to Relational Databases",
       "RDF Access to Relational Databases");

# $Id: 85-find-by.t,v 1.2 2004/07/03 06:17:50 asc Exp $
