#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;
use XML::RSS::LibXML;

{
    my $rss = XML::RSS::LibXML->new( version => '2.0' );
    $rss->add_module(
            prefix => 'content',
            uri => 'http://purl.org/rss/1.0/modules/content/'
        );
    $rss->add_item(
            title   => 'title',
            content => { encoded => 'this is content' },
        );

    # TEST
    like $rss->as_string, qr/this is content/;
}

{
    my $rss = XML::RSS::LibXML->new( version => '2.0' );
    eval {
        $rss->add_module(
            prefix => 'a/b',
            uri => 'http://foobar.tld/foo/'
        );
    };
    # TEST
    like ($@, qr{\Aa namespace prefix should look like},
        "Testing for invalidty of / as a prefix char");
}

{
    my $rss = XML::RSS::LibXML->new( version => '2.0' );
    eval {
        $rss->add_module(
            prefix => 'Foobar',
            uri => 'http://foobar.tld/foo/'
        );
    };
    # TEST
    ok !$@, "Testing for validity of ucfirst prefix";
}

{
    my $rss = XML::RSS::LibXML->new( version => '2.0' );
    eval {
        $rss->add_module(
            prefix => "myprefix",
        );
    };
    # TEST
    like ($@, qr{\Aa URI must be provided},
        "Testing for exception upon an unspecified URI.");
}
