#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use File::Spec;
use XML::RSS::LibXML;

SKIP: {
    my $rssfile = File::Spec->catfile('t', 'data', 'rss-permalink.xml');
    skip("rt #42536", 4) if ! -f $rssfile;

    my $rss = new XML::RSS::LibXML;
    $rss->parsefile($rssfile);
    my $item_with_guid_true = $rss->{'items'}->[0];
    my $item_with_guid_missing = $rss->{'items'}->[1];
    my $item_with_guid_false = $rss->{'items'}->[2];
    
    # TEST
    is ($item_with_guid_true->{"permaLink"}, 
        "http://community.livejournal.com/lj_dev/714037.html",
        "guid's isPermaLink is set to true, so the item permalink property should be set to the value of the guid tag"
    );
    
    # TEST
    is ($item_with_guid_missing->{"permaLink"}, 
        "http://community.livejournal.com/lj_dev/713810.html",
        "guid's isPermaLink is missing, so the item permalink property should be set to the value of the guid tag"
    );
    
    # TEST
    ok ((!$item_with_guid_false->{"permaLink"}),
        "guid's isPermaLink is false, so the permalink should be false"
    );
    
    # TEST
    is ($item_with_guid_false->{"guid"}, 
        "http://community.livejournal.com/lj_dev/713549.html",
        "guid's isPermaLink is false so item->{guid} should be equal to" .
        " the contents of the guid element"
    );
}
