#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use XML::RSS;

{
    my $rss = XML::RSS->new();

    $rss->parsefile(File::Spec->catfile(File::Spec->curdir(), "t", "data", "merlyn1.rss"));
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
    my $rss = XML::RSS->new(version => "2.0");

    $rss->parsefile(File::Spec->catfile(File::Spec->curdir(), "t", "data", "merlyn1.rss"));

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
    my $rss = XML::RSS->new();

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

{
    my $rss = XML::RSS->new();

    $rss->parsefile(
        File::Spec->catfile(
            File::Spec->curdir(), "examples", "1.0", "rss1.0.rdf",
        )
    );

    # TEST
    is (
        $rss->image("rdf:resource"),
        "http://freshmeat.net/images/fm.mini.jpg",
        "rdf:resource for image was read correctly.",
    );
}
