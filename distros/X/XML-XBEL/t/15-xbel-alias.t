use strict;
use Test::More;

plan tests => 10;

use_ok("XML::XBEL::Alias");
use_ok("XML::XBEL::Bookmark");
use_ok("XML::XBEL::Folder");

my $folder = XML::XBEL::Folder->new();
isa_ok($folder, "XML::XBEL::Folder");

my $bookmark = XML::XBEL::Bookmark->new({href => "http://foobar.com",
					 id   => "foobar"});
isa_ok($bookmark, "XML::XBEL::Bookmark");

my $alias  = XML::XBEL::Alias->new();
isa_ok($alias,"XML::XBEL::Alias");

ok($alias->ref($bookmark),
   "aliased bookmark");

ok($folder->add_bookmark($bookmark),	
   "added bookmark to folder");

ok($folder->add_alias($alias),	
   "added alias to folder");

cmp_ok($alias->ref(),"eq","foobar",
       "alias is foobar");

# $Id: 15-xbel-alias.t,v 1.2 2004/06/23 06:23:57 asc Exp $

