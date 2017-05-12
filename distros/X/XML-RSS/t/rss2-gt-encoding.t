#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

if (eval "require Test::Differences") {
    Test::Differences->import;
    plan tests => 2;
}
else {
    plan skip_all => 'Test::Differences required';
}

use_ok('XML::RSS');

my $rss = XML::RSS->new(version => '2.0');

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

my $expected_encoded_html = '<description>&#x3C;a href=&#x22;http://www.shlomifish.org/&#x22;&#x3E;&#x3C;span style=&#x22;color:#658912&#x22;&#x3E;Whoa&#x3C;/span&#x3E;&#x3C;/a&#x3E;</description>';

eq_or_diff($string, $expected_encoded_html, "Testing for a correctly encoded HTML");

1;

