#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

use XML::RSS;
use File::Spec;

{
    my $rss = XML::RSS->new();

    $rss->parse(<<"EOF");
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

    $rss->parsefile(
        File::Spec->catfile(
            File::Spec->curdir(),
            "examples",
            "2.0",
            "rss-2.0-sample-from-rssboard-multiple-skip-days-and-hours.xml"
        )
    );

    # TEST
    is_deeply(
        $rss->{'skipHours'}->{'hour'},
        [qw(0 1 2 22 23)],
        "skipHours/hour is parsed into an array with the individual elements",
    );

    # TEST
    is_deeply(
        $rss->{'skipDays'}->{'day'},
        [qw(Saturday Sunday)],
        "skipDays/day is parsed into an array with indiv elements",
    );

    # TEST
    is_deeply(
        $rss->{'channel'}->{'category'},
        [qw(Media Texas)],
        "Multiple categories",
    );
}

{
    my $rss = XML::RSS->new();

    $rss->parsefile(
        File::Spec->catfile(
            File::Spec->curdir(),
            "t", "data", "2.0",
            "sf-hs-with-pubDate.rss"
        ),
    );

    # TEST
    is_deeply(
        $rss->{'items'}->[0]->{'category'},
        [qw(
            mathml
            mathematics
            math
            dos
            jokes
            tucan
            ideas
            mathventures
            unixdoc
        )],
        "items/category is an array-ref",
    );
}

{
    my $rss = XML::RSS->new();

    $rss->parsefile(
        File::Spec->catfile(
            File::Spec->curdir(),
            "t", "data", "2.0",
            "no-desc.rss",
        ),
    );

    # TEST
    ok (!defined($rss->channel("description")),
        "description is undefined if not present"
    );

    # TEST
    ok (!defined($rss->channel("title")),
        "title is undefined if not present",
    );
}

{
    my $rss = XML::RSS->new();

    $rss->parsefile(
        File::Spec->catfile(
            File::Spec->curdir(),
            "t", "data", "2.0",
            "empty-desc.rss",
        ),
    );

    # TEST
    is ($rss->channel("description"),
        "",
        "description is an empty string if an empty tag"
    );

    # TEST
    is ($rss->channel("title"),
        "",
        "title is an empty string if an empty tasg",
    );
}

{
    my $rss = XML::RSS->new();

    $rss->parsefile(
        File::Spec->catfile(
            File::Spec->curdir(),
            qw(examples 2.0 flickr-rss-with-both-desc-and-media-desc.xml)
        ),
        { hashrefs_instead_of_strings => 1 },
    );

    # TEST
    like ($rss->{'items'}->[0]->{'description'},
        qr{\A\Q<p><a href="http://www.flickr.com/people/shlomif/"\E},
        "Regular description and was not over-rided by media:description",
    );

    # TEST
    like ($rss->{'items'}->[0]
              ->{'http://search.yahoo.com/mrss/'}->{'description'}
              ->{'content'},
        qr{\A<p>No active bugs},
        "media:desc content is OK.",
    );

    # TEST
    is ($rss->{'items'}->[0]
              ->{'http://search.yahoo.com/mrss/'}->{'description'}
              ->{'type'},
        "html",
        "media:desc type is OK.",
    );
}

{
    my $rss = XML::RSS->new();

    $rss->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE title [ <!ELEMENT title ANY >
<!ENTITY xxe SYSTEM "file:///etc/passwd" >]>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
    <title>The Blog</title>
    <link>http://example.com/</link>
    <description>A blog about things</description>
    <lastBuildDate>Mon, 03 Feb 2014 00:00:00 -0000</lastBuildDate>
    <item>
        <title>Without&xxe;Entity</title>
        <link>http://example.com</link>
        <description>a post</description>
        <author>author@example.com</author>
        <pubDate>Mon, 03 Feb 2014 00:00:00 -0000</pubDate>
    </item>
</channel>
</rss>
EOF

    # TEST
    is ($rss->{items}->[0]->{title}, "WithoutEntity",
        "Fix for RT #100660 - XML External Entities Exploit",
    );
}
