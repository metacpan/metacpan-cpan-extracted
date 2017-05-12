use strict;
use Test::More;

plan tests => 13;

use constant LOCAL_TITLE => "xbel";
use constant LOCAL_DESC  => "extensible bookmark language";

use constant LOCAL_NEW_TITLE => "XBEL";
use constant LOCAL_NEW_DESC  => "XML Bookmarks Exchange Language";

use_ok("XML::XBEL");

my $xbel = XML::XBEL->new();
isa_ok($xbel,"XML::XBEL");

ok($xbel->new_document({title    => LOCAL_TITLE,
			desc     => LOCAL_DESC,
			encoding => "ISO-8859-1"}),
   "create new document");

#

# use Data::Dumper;
# diag(Dumper($xbel));

cmp_ok($xbel->title(),"eq",LOCAL_TITLE,
       sprintf("title is %s",LOCAL_TITLE));

ok($xbel->title(LOCAL_NEW_TITLE),
   sprintf("set new title as %s",LOCAL_NEW_TITLE));

cmp_ok($xbel->title(),"eq",LOCAL_NEW_TITLE,
       sprintf("new title is %s",LOCAL_NEW_TITLE));

#

cmp_ok($xbel->desc(),"eq",LOCAL_DESC,
       sprintf("description is %s",LOCAL_DESC));

ok($xbel->desc(LOCAL_NEW_DESC),
   sprintf("set new description as %s",LOCAL_NEW_DESC));

cmp_ok($xbel->desc(),"eq",LOCAL_NEW_DESC,
       sprintf("new description is %s",LOCAL_NEW_DESC));

#

ok($xbel->add_bookmark({title    =>"aaron's cpan stuff",
		          href     => "http://search.cpan.org/~ascope",
		          desc     => "shameless huckerism",
			  added    => "2004-06-22T18:03:07 -0400",
			  modified => "2004-06-22T18:03:07 -0400"}),
   "added new bookmark");

#

ok($xbel->add_folder({title => "a sub directory",
			added => "2004-06-22T18:03:07 -0400"}),
   "added new folder");

#

ok($xbel->add_separator(),
   "added separator");

ok($xbel->add_alias({ref=>"123"}),
   "added alias to bookmark 123");

# $Id: 50-xbel.t,v 1.5 2005/03/26 18:44:48 asc Exp $
