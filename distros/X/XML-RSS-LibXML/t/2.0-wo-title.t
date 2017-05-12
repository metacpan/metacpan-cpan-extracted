#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

# TEST
use_ok('XML::RSS::LibXML');

my $rss = XML::RSS::LibXML->new(version => '2.0');

$rss->channel(
    title          => 'freshmeat.net',
    'link'           => 'http://freshmeat.net',
    language       => 'en',
    description    => 'the one-stop-shop for all your Linux software needs',
    rating         => '(PICS-1.1 "http://www.classify.org/safesurf/" 1 r (SS~~000 1))',
    copyright      => 'Copyright 1999, Freshmeat.net',
    pubDate        => 'Thu, 23 Aug 1999 07:00:00 GMT',
    lastBuildDate  => 'Thu, 23 Aug 1999 16:20:26 GMT',
    docs           => 'http://www.blahblah.org/fm.cdf',
    managingEditor => 'scoop@freshmeat.net',
    webMaster      => 'scoop@freshmeat.net'
    );

$rss->add_item(
    # creates a guid field with permaLink=true
    permaLink  => "http://freshmeat.net/news/1999/06/21/930003829.html",
    # alternately creates a guid field with permaLink=false
    # guid     => "gtkeyboard-0.85
    enclosure   => { url=>"http://www.foo.tld/", type=>"application/x-bittorrent" },
    description => 'My Life Changed Absolutely',
);

my $string = $rss->as_string();

# TEST
ok (
    (index($string, 
            '<description>My Life Changed Absolutely</description>'
        ) >= 0
    ),
    "Testing for the item being rendered."
);

1;
