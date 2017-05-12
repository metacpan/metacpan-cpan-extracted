#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 19;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;
my @titles = (
    ['entry_source_title.xml','Example Atom'],
    ['entry_source_title_escaped_markup.xml','Example <b>Atom</b>','html'],
    ['entry_source_title_inline_markup_2.xml','History of the &lt;blink&gt; tag','xhtml'],
    ['entry_source_title_inline_markup.xml','Example <b>Atom</b>','xhtml'],
    ['entry_source_title_text_plain.xml','Example Atom','text']
);

foreach my $t (@titles) {
    my $feed = get_feed($t->[0]);
    my @e = $feed->entries;
    my $s = $e[0]->source;
    ok(ref $s eq 'XML::Atom::Syndication::Source');
    my $title = $s->title;
    ok(ref $title eq 'XML::Atom::Syndication::Text');
    ok($title->body eq $t->[1]);    
    ok($title->type eq $t->[2]) if $t->[2];
}

1;