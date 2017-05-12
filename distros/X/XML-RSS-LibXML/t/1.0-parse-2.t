#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use File::Spec;
use XML::RSS::LibXML;

SKIP: {
    my $rssfile = File::Spec->catfile(File::Spec->curdir(), "t", "data", "merlyn1.rss");
    skip("rt #42536", 3) if ! -f $rssfile;
    my $rss = XML::RSS::LibXML->new();

    $rss->parsefile($rssfile);
    {
        my $item = $rss->{items}->[0];

        # TEST
        is ($item->{dc}->{creator}, "merlyn", 
            "item[0]/dc/creator in RSS 1.0"
        );

        # TEST
        is ($item->{dc}->{date}, "2006-10-05T14:56:02+00:00",
            "item[0]/dc/date in RSS 1.0"
        );

        # TEST
        is ($item->{dc}->{subject}, "journal",
            "item[0]/dc/subject in RSS 1.0"
        );
    }
}

SKIP: {
    my $rssfile = File::Spec->catfile(File::Spec->curdir(), "t", "data", "merlyn1.rss");
    skip("rt #42536", 3) if ! -f $rssfile;
    my $rss = XML::RSS::LibXML->new(version => "2.0");

    $rss->parsefile($rssfile);

    {
        my $item = $rss->{items}->[0];

        # TEST
        is ($item->{dc}->{creator}, "merlyn", 
            "item[0]/dc/creator in RSS 1.0"
        );

        # TEST
        is ($item->{dc}->{date}, "2006-10-05T14:56:02+00:00",
            "item[0]/dc/date in RSS 1.0"
        );

        # TEST
        is ($item->{dc}->{subject}, "journal",
            "item[0]/dc/subject in RSS 1.0"
        );
    }
}


{
    my $rss = XML::RSS::LibXML->new();

    $rss->parsefile(
        File::Spec->catfile(
            File::Spec->curdir(), "t", "data", "1.0","with_content.rdf"
        )
    );

    {
        my $item = $rss->{items}->[0];

        # TEST
        is ($item->{content}->{encoded}, "<p>Hello!</p>",
            "Testing the \"content\" namespace");
    }
}
