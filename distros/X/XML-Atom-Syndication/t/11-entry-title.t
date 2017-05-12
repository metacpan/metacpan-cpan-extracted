#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 17;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @titles = (
    ['entry_title.xml','Example Atom'],
    ['entry_title_escaped_markup.xml','Example <b>Atom</b>','html'],
    ['entry_title_inline_markup_2.xml','History of the &lt;blink&gt; tag','xhtml'],
    ['entry_title_inline_markup.xml','Example <b>Atom</b>','xhtml'],
    ['entry_title_text_plain.xml','Example Atom','text'],
    ['entry_title_text_plain_brackets.xml','History of the <blink> tag','text']
);

foreach my $t (@titles) {
    my $feed = get_feed($t->[0]);
    my @e = $feed->entries;
    my $title = $e[0]->title;
    ok(ref $title eq 'XML::Atom::Syndication::Text');
    ok($title->body eq $t->[1]);    
    ok($title->type eq $t->[2]) if $t->[2];
}

1;