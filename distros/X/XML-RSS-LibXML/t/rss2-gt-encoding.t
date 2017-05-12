#!/usr/bin/perl -w

use strict;
use Test::More;
plan tests => 2;

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
    title => "GTKeyboard 0.85",
    # creates a guid field with permaLink=true
    permaLink  => "http://freshmeat.net/news/1999/06/21/930003829.html",
    # alternately creates a guid field with permaLink=false
    # guid     => "gtkeyboard-0.85
    enclosure   => { url=>"http://www.foo.tld/", type=>"application/x-bittorrent" },
    description => '<a href="http://www.shlomifish.org/"><span style="color:#658912">Whoa</span></a>'
);

my ($string) = grep { m/shlomifish/ } split /\n/, $rss->as_string();

# This works differently from XML::RSS
my $expected_encoded_html = '<description>&lt;a href="http://www.shlomifish.org/"&gt;&lt;span style="color:#658912"&gt;Whoa&lt;/span&gt;&lt;/a&gt;</description>';

$string =~ s/^\s+//; $string =~ s/\s+$//;
is($string, $expected_encoded_html, "Testing for a correctly encoded HTML");

1;

