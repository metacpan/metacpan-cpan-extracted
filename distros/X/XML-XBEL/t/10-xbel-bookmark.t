use strict;
use Test::More;

plan tests => 16;

use constant LOCAL_TITLE => "bookmark test";
use constant LOCAL_DESC  => "hello world";
use constant LOCAL_HREF  => "http://127.0.0.1";
use constant LOCAL_ID    => "";

use constant LOCAL_NEW_TITLE => "foo bar";
use constant LOCAL_NEW_HREF  => "http://10.0.0.1";
use constant LOCAL_NEW_DESC  => "this is the network of our disconnect";
use constant LOCAL_NEW_ID    => "123";

use_ok("XML::XBEL::Bookmark");

my $bm = XML::XBEL::Bookmark->new({title => LOCAL_TITLE,
				   desc  => LOCAL_DESC,
				   href  => LOCAL_HREF});

isa_ok($bm,"XML::XBEL::Bookmark");

#

cmp_ok($bm->title(),"eq",LOCAL_TITLE,
       sprintf("title is %s",LOCAL_TITLE));

ok($bm->title(LOCAL_NEW_TITLE),
   sprintf("set new title as %s",LOCAL_NEW_TITLE));

cmp_ok($bm->title(),"eq",LOCAL_NEW_TITLE,
       sprintf("new title is %s",LOCAL_NEW_TITLE));

#

cmp_ok($bm->desc(),"eq",LOCAL_DESC,
       sprintf("description is %s",LOCAL_DESC));

ok($bm->desc(LOCAL_NEW_DESC),
   sprintf("set new description as %s",LOCAL_NEW_DESC));

cmp_ok($bm->desc(),"eq",LOCAL_NEW_DESC,
       sprintf("new description is %s",LOCAL_NEW_DESC));

#

cmp_ok($bm->id(),"eq",LOCAL_ID,
       sprintf("id is %s",LOCAL_ID));

ok($bm->id(LOCAL_NEW_ID),
   sprintf("set new id as %s",LOCAL_NEW_ID));

cmp_ok($bm->id(),"eq",LOCAL_NEW_ID,
       sprintf("new id is %s",LOCAL_NEW_ID));

#

cmp_ok($bm->href(),"eq",LOCAL_HREF,
      sprintf("href is %s",LOCAL_HREF));

ok($bm->href(LOCAL_NEW_HREF),
   sprintf("set href as %s",LOCAL_NEW_HREF));

cmp_ok($bm->href(),"eq",LOCAL_NEW_HREF,
      sprintf("new href is %s",LOCAL_NEW_HREF));

#

ok($bm->added(),
   sprintf("bookmark added %s",$bm->added()));

ok($bm->modified(),
   sprintf("bookmark modified %s",$bm->modified()));

# $Id: 10-xbel-bookmark.t,v 1.3 2004/06/23 06:30:21 asc Exp $

