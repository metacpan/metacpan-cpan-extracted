#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 22;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @links = (
    ['feed_link_href.xml','href','http://www.example.com/'],
    ['feed_link_hreflang.xml','hreflang','en'],
    ['feed_link_length.xml','length','42301'],
    ['feed_link_rel.xml','rel','alternate'],
    ['feed_link_rel_related.xml','rel','related'],
    ['feed_link_rel_self.xml','rel','self'],
    ['feed_link_rel_via.xml','rel','via'],
    ['feed_link_title.xml','title','Example title'],
    ['feed_link_type.xml','type','text/html'],
);

foreach my $l (@links) {
    my $feed = get_feed($l->[0]);
    my $link = $feed->link;
    ok(ref $link eq 'XML::Atom::Syndication::Link');
    my $meth = $l->[1];
    ok($link->$meth eq $l->[2]);
}

my $feed = get_feed('feed_link_multiple.xml');
my @links2 = $feed->link;
ok(@links2 == 2);
ok(ref $links2[0] eq 'XML::Atom::Syndication::Link');
ok($links2[0]->href eq 'http://www.example.com/');
ok($links2[1]->href eq 'http://www.example.com/post');

1;