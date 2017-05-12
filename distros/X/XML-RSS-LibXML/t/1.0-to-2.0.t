#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;

use Test::More tests => 8;

use XML::RSS::LibXML;

SKIP: {
    my $rssfile = File::Spec->catfile(File::Spec->curdir(), "t", "data", "merlyn1.rss");
    skip("rt #42536", 2) if ! -f $rssfile;
    my $rss = XML::RSS::LibXML->new;
    $rss->parsefile($rssfile);

    $rss->{output} = "2.0";
    my $string = $rss->as_string;

    # TEST
    like(
        $string,
        qr{<lastBuildDate>Sat, 14 Oct 2006 21:15:36 [+-]0000</lastBuildDate>},
        "Correct date was found",
    );

    # TEST
    like(
        $string,
        qr{<pubDate>Sat, 14 Oct 2006 21:15:36 [+-]0000</pubDate>},
        "Correct pubDate was found",
    );    
}

SKIP: {
    my $rssfile = File::Spec->catfile(File::Spec->curdir(), "t", "data", "merlyn1.rss");
    skip("rt #42536", 2) if ! -f $rssfile;
    my $rss = XML::RSS::LibXML->new;
    $rss->parsefile($rssfile);

    $rss->{output} = "0.91";
    my $string = $rss->as_string;

    # TEST
    like(
        $string,
        qr{<pubDate>Sat, 14 Oct 2006 21:15:36 [+-]0000</pubDate>},
        "Correct date was found in 1.0 -> 0.91 conversion (pubDate)",
    );

    # TEST
    like(
        $string,
        qr{<lastBuildDate>Sat, 14 Oct 2006 21:15:36 [+-]0000</lastBuildDate>},
        "Correct date was found in 1.0 -> 0.91 conversion (lastBuildDate)",
    );
}

SKIP: {
    my $rssfile = File::Spec->catfile(File::Spec->curdir(), "t", "data", "2.0","sf-hs-with-pubDate.rss");
    skip("rt #42536", 2) if (! -f $rssfile);

    my $rss = XML::RSS::LibXML->new;
    $rss->parsefile($rssfile);

    $rss->{output} = "1.0";
    my $string = $rss->as_string;

    my $index = index($string, qq{<dc:date>2006-09-24T10:12:49Z</dc:date>\n});
    # TEST
    ok ($index >= 0,
        "Correct date was found in 2.0 -> 1.0 conversion",
    );

    my $item_index = index($string, "<item");

    # TEST
    ok ($index < $item_index,
        "Correct date comes before the first item (hence not contained within)."
    );
}

SKIP: {
    my $rssfile = File::Spec->catfile(File::Spec->curdir(), "t", "data", "2.0","sf-hs-with-lastBuildDate.rss");
    skip("rt #42536", 2);

    my $rss = XML::RSS::LibXML->new;

    $rss->parsefile($rssfile);

    $rss->{output} = "1.0";
    my $string = $rss->as_string;

    my $index = index($string, qq{<dc:date>2006-09-24T10:12:49Z</dc:date>\n});
    # TEST
    ok ($index >= 0,
        "Correct date was found in 2.0 -> 1.0 conversion",
    );

    my $item_index = index($string, "<item");

    # TEST
    ok ($index < $item_index,
        "Correct date comes before the first item (hence not contained within)."
    );
}
