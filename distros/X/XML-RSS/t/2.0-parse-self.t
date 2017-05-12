#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use XML::RSS;

my $text = <<"EOF";
<?xml version="1.0" encoding="UTF-8" ?>
<?xml-stylesheet href="/rss/news/journalism.xsl" type="text/xsl"?>
<rss version="2.0">
<channel><title>Journalism - Topix.net</title>
<link>http://www.topix.net/news/journalism</link>
<description>News on Journalism from Topix.net</description>
<language>en-us</language>
<copyright>Copyright 2006, Topix.net</copyright>
<image><title>Topix.net</title>
<link>http://www.topix.net/</link>
<url>http://www.topix.net/pics/logo4.gif</url>
</image>
<item>
<title>Gannett Reportedly Mulling Tribune Bid </title>
<link>http://topix.net/r/0l1Qq8DEtErajq5wDAIHZ0RavmEQ=2BIyZGBfGjcVwyQpW0DFdgUcy=2FtbxGNgMtYEdbU7ucVOR=2Bw2Bu6K4EDvt9=2B7ILEWB6Q5Zxy64f9JxkGU92am=2FLdMjb=2FCxbmfNuBQX6</link>
<description><![CDATA[Gannett Co., the largest newspaper publisher in the nation, has surfaced as a potential buyer of the Chicago Tribune and other newspapers owned by Tribune Co., according to published reports.<br/><a href="http://www.topix.net/forum/link/thread?forum=news/journalism&artsig=435ed4cd01">Comment</a>]]></description>
<source url="http://www.topix.net">The Associated Press on Topix.net</source>
<pubDate>Mon, 13 Nov 2006 15:50:44 GMT</pubDate>
<guid isPermaLink="false">eQE3vmbXGCzvaHn0deSSyA</guid>
<enclosure url="http://64.13.133.31/pics/a49e1416bf69bc4399d74c818517214d-l" length="3597" type="image/jpg" />
</item>
<textInput>
<title>Journalism - Topix.net</title>
<description>Use the text input below to search Topix.net</description>
<name>q</name>
<link>http://www.topix.net/search/</link>
</textInput></channel>
</rss>
EOF

{
    my $rss = XML::RSS->new();

    # TEST
    is ($rss->parse($text)->{textinput}->{link},
        "http://www.topix.net/search/",
        "->parse() returns the object again"
    );

    # TEST
    is ($rss->{textinput}->{link}, "http://www.topix.net/search/",
        "Testing for textinput link"
    );

    # TEST
    is ($rss->{channel}->{link}, "http://www.topix.net/news/journalism",
        "Testing for channel link"
    );
}

{
    my $rss = XML::RSS->new();

    # TEST
    is ($rss->parsefile(
            File::Spec->catfile("t", "data", "2.0", "sf-hs-with-pubDate.rss")
        )->{channel}->{link},
        "http://community.livejournal.com/shlomif_hsite/",
        "->parsefile() returns the object",
    );
}
