#!/usr/bin/perl

# Test the strict mode of RSS 0.9 and RSS 0.91

use strict;
use warnings;

use Test::More;

use XML::RSS::LibXML;

sub item_throws_like
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($rss, $params, $regex, $msg) = @_;
    eval {
        $rss->add_item(@$params);
    };

    like ($@, $regex, $msg);
}

{
    my $rss = XML::RSS::LibXML->new(version => "0.9");

    $rss->strict(1);

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "the one-stop-shop for all your Linux software needs",
        );

    # TEST
    item_throws_like($rss, [link => "http://foobar.tld/from/"], 
        qr{\Atitle and link elements are required},
        "strict - checking for exception on non-specified title"
    );

    # TEST
    item_throws_like($rss, [title => "From Foobar"], 
        qr{\Atitle and link elements are required},
        "strict - checking for exception on non-specified link"
    );

    # TEST
    item_throws_like($rss, [link => "http://foobar.tld/", 
        title => ("Very long title indeed" x 50)], 
        qr{\Atitle cannot exceed},
        "strict - checking for long title"
    );

    # TEST
    item_throws_like($rss, [
        link => "http://" . ("foobarminimoni" x 200) . ".tld/", 
        title => "Short Title"
        ], 
        qr{\Alink cannot exceed},
        "strict - checking for long link"
    );

    # TEST
    item_throws_like($rss, [
        link => "http://foobar.tld/from/", 
        title => "Short Title",
        description => ("This description is way too long!" x 100),
        ],
        qr{\Adescription cannot exceed},
        "strict - checking for a long description"
    );
}

{
    my $rss = XML::RSS::LibXML->new(version => "0.9");

    $rss->strict(1);

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "the one-stop-shop for all your Linux software needs",
        );

    foreach my $i (1 .. 15)
    {
        $rss->add_item(
            link => "http://foobar.tld/item-$i",
            title => "Item $i",
        );
    }

    # TEST
    item_throws_like($rss, [
        link => "http://foobar.tld/from/", 
        title => "Short Title",
        description => "Good description",
        ],
        qr{\Atotal items cannot exceed},
        "strict - checking for too many items"
    );
}

{
    my $rss = XML::RSS::LibXML->new(version => "0.9");

    $rss->strict(1);

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "the one-stop-shop for all your Linux software needs",
        stupid_key => ("I think therefore I am." x 1000),
        );

    # TEST
    ok (1, "Can add unknown keys of unlimited size without restriction");

}

{
    my $rss = XML::RSS::LibXML->new(version => "0.9");

    $rss->strict(1);

    eval {
        $rss->channel(
            title => "freshmeat.net",
            link  => "http://freshmeat.net",
            description => ("I think therefore I am." x 1000),
        );
    };

    # TEST
    like ($@, qr{\Adescription cannot exceed 500 characters in length},
        "Testing for exception thrown on a very long key"
    );
}

{
    my $rss = XML::RSS::LibXML->new(version => "0.9");

    $rss->strict(1);

    eval {
        $rss->skipHours(
            hour => 5,
        );
    };

    # TEST
    like ($@, qr{\AUnregistered entity: Can't access skipHours field in object of class},
        "Testing for exception thrown on an unknown field"
    );
}

{
    my $rss = XML::RSS::LibXML->new(version => "0.9");

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "the one-stop-shop for all your Linux software needs",
        );

    # TEST
    is ($rss->channel()->{title},
        "freshmeat.net",
        "Testing for an AUTOLOAD accessor with 0 arguments"
    );
    
    # TEST
    is ($rss->channel('title'),
        "freshmeat.net",
        "Testing for an AUTOLOAD accessor with 1 argument"
    );
}

{
    my $rss = XML::RSS::LibXML->new(version => "0.91");

    $rss->strict(1);

    eval {
        $rss->skipDays(
            day => "FoolambdaCroakThemOfMonetaryJudgement"
        );
    };

    # TEST
    like ($@, qr{\Aday cannot exceed 10 characters in length},
        "Testing for exception thrown on a key for 0.91"
    );
}

done_testing;

