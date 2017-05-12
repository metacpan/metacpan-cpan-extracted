#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 14;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @titles = (
    ['feed_subtitle.xml','Example Atom'],
    ['feed_subtitle_escaped_markup.xml','Example <b>Atom</b>','html'],
    ['feed_subtitle_inline_markup_2.xml','History of the &lt;blink&gt; tag','xhtml'],
    ['feed_subtitle_inline_markup.xml','Example <b>Atom</b>','xhtml'],
    ['feed_subtitle_text_plain.xml','Example Atom','text']
);

foreach my $t (@titles) {
    my $feed = get_feed($t->[0]);
    my $title = $feed->subtitle;
    ok(ref $title eq 'XML::Atom::Syndication::Text');
    ok($title->body eq $t->[1]);    
    ok($title->type eq $t->[2]) if $t->[2];
}

1;