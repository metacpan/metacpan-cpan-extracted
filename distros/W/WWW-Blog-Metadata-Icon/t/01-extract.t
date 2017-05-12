# $Id: 01-extract.t 1933 2006-04-22 04:53:48Z btrott $

use strict;
use Test::More tests => 6;
use WWW::Blog::Metadata;

my $meta;

$meta = WWW::Blog::Metadata->extract_from_uri('http://btrott.typepad.com/')
    or die WWW::Blog::Metadata->errstr;
is($meta->foaf_icon_uri, 'http://btrott.typepad.com/benffshirt.jpg');
is($meta->icon_uri, 'http://btrott.typepad.com/benffshirt.jpg');
is($meta->favicon_uri, 'http://btrott.typepad.com/favicon.ico');

$meta = WWW::Blog::Metadata->extract_from_uri('http://www.typepad.com/')
    or die WWW::Blog::Metadata->errstr;
is($meta->favicon_uri, 'http://www.typepad.com/favicon.ico');
is($meta->icon_uri, 'http://www.typepad.com/favicon.ico');
ok(!$meta->foaf_icon_uri);
