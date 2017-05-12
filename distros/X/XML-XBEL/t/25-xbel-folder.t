use strict;
use Test::More;

plan tests => 18;

use constant LOCAL_TITLE => "folder test";
use constant LOCAL_DESC  => "bag of holding";
use constant LOCAL_ID    => "";

use constant LOCAL_NEW_TITLE => "perl";
use constant LOCAL_NEW_DESC  => "there's more than one way to do it";
use constant LOCAL_NEW_ID    => "japh";

use_ok("XML::XBEL::Folder");

my $folder = XML::XBEL::Folder->new({title => LOCAL_TITLE,
				     desc  => LOCAL_DESC,
				     added => "2004-06-22T18:03:07 -0400"});

isa_ok($folder,"XML::XBEL::Folder");

#

cmp_ok($folder->title(),"eq",LOCAL_TITLE,
       sprintf("title is %s",LOCAL_TITLE));

ok($folder->title(LOCAL_NEW_TITLE),
   sprintf("set new title as %s",LOCAL_NEW_TITLE));

cmp_ok($folder->title(),"eq",LOCAL_NEW_TITLE,
       sprintf("new title is %s",LOCAL_NEW_TITLE));

#

cmp_ok($folder->desc(),"eq",LOCAL_DESC,
       sprintf("description is %s",LOCAL_DESC));

ok($folder->desc(LOCAL_NEW_DESC),
   sprintf("set new description as %s",LOCAL_NEW_DESC));

cmp_ok($folder->desc(),"eq",LOCAL_NEW_DESC,
       sprintf("new description is %s",LOCAL_NEW_DESC));

#

cmp_ok($folder->id(),"eq",LOCAL_ID,
       sprintf("id is %s",LOCAL_ID));

ok($folder->id(LOCAL_NEW_ID),
   sprintf("set new id as %s",LOCAL_NEW_ID));

cmp_ok($folder->id(),"eq",LOCAL_NEW_ID,
       sprintf("new id is %s",LOCAL_NEW_ID));

#

cmp_ok($folder->folded(),"eq","yes",
       "folder is folded");

$folder->folded(0);

cmp_ok($folder->folded(),"eq","no",
       "folder is not folded");

#

ok($folder->added(),
   sprintf("folder added %s",$folder->added()));

#

ok($folder->add_bookmark({title    =>"aaron's cpan stuff",
		          href     => "http://search.cpan.org/~ascope",
		          desc     => "shameless huckerism",
			  added    => "2004-06-22T18:03:07 -0400",
			  modified => "2004-06-22T18:03:07 -0400"}),
   "added new bookmark");

#

ok($folder->add_folder({title => "a sub directory",
			added => "2004-06-22T18:03:07 -0400"}),
   "added new folder");

#

ok($folder->add_separator(),
   "added separator");

ok($folder->add_alias({ref=>"123"}),
   "added alias to bookmark 123");

# $Id: 25-xbel-folder.t,v 1.4 2004/06/23 06:30:21 asc Exp $
