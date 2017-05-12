#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 24;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @links = (
    ['entry_link_href.xml','href','http://www.example.com/'],
    ['entry_link_hreflang.xml','hreflang','en'],
    ['entry_link_length.xml','length','42301'],
    ['entry_link_rel.xml','rel','alternate'],
    ['entry_link_rel_enclosure.xml','rel','enclosure'],
    ['entry_link_rel_related.xml','rel','related'],
    ['entry_link_rel_self.xml','rel','self'],
    ['entry_link_rel_via.xml','rel','via'],
    ['entry_link_title.xml','title','Example title'],
    ['entry_link_type.xml','type','text/html'],
);

foreach my $l (@links) {
    my $feed = get_feed($l->[0]);
    my @e = $feed->entries;
    my $link = $e[0]->link;
    ok(ref $link eq 'XML::Atom::Syndication::Link');
    my $meth = $l->[1];
    ok($link->$meth eq $l->[2]);
}

my $feed = get_feed('entry_link_multiple.xml');
my @e = $feed->entries;
my @links2 = $e[0]->link;
ok(@links2 == 2);
ok(ref $links2[0] eq 'XML::Atom::Syndication::Link');
ok($links2[0]->href eq 'http://www.example.com/');
ok($links2[1]->href eq 'http://www.example.com/post');

1;