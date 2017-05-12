#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 16;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @titles = (
    ['feed_title.xml','Example Atom'],
    ['feed_title_escaped_markup.xml','Example <b>Atom</b>','html'],
    ['feed_title_inline_markup_2.xml','History of the &lt;blink&gt; tag','xhtml'],
    ['feed_title_inline_markup.xml','Example <b>Atom</b>','xhtml'],
    ['feed_title_text_plain.xml','Example Atom','text']
);

foreach my $t (@titles) {
    my $feed = get_feed($t->[0]);
    my $title = $feed->title;
    ok(ref $title eq 'XML::Atom::Syndication::Text');
    ok($title->body eq $t->[1]);    
    ok($title->type eq $t->[2]) if $t->[2];
}

# xml:base test.
my $feed1 = get_feed('relative_uri.xml');
my $title1 = $feed1->title;
ok($title1->base eq 'http://example.com/test/');

# xml:lang test.
my $feed2 = get_feed('x-lang.xml');
my $title2 = $feed2->title;
ok($title2->lang eq 'en');

1;