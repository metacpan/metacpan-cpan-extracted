#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use XML::RSS;

{
    eval
    {
        my $rss = XML::RSS->new( version => '1.0' );

        $rss->add_item(
            # title =>  "Some text",
            link  => 'http://a.com',
            description => 'abc',
        );
        $rss->as_string;
    };

    my $Err = $@;

    my $s = 'Item No. 0 is missing the "title" field.';

    # TEST
    like ($Err, qr/\A\Q$s\E/, "Exception on missing title field");
}

{
    eval
    {
        my $rss = XML::RSS->new( version => '1.0' );

        $rss->add_item(
            title =>  "Some text",
            # link  => 'http://a.com',
            description => 'abc',
        );
        $rss->as_string;
    };

    my $Err = $@;

    my $s = 'Item No. 0 is missing "about" or "link" fields.';

    # TEST
    like ($Err, qr/\A\Q$s\E/, "Exception on missing link field");
}
