#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 14;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @summaries = (
    ['entry_summary.xml','Example Atom'],
    ['entry_summary_escaped_markup.xml','Example <b>Atom</b>','html'],
    ['entry_summary_inline_markup_2.xml','History of the &lt;blink&gt; tag','xhtml'],
    ['entry_summary_inline_markup.xml','Example <b>Atom</b>','xhtml'],
    ['entry_summary_text_plain.xml','Example Atom','text']
);

foreach my $s (@summaries) {
    my $feed = get_feed($s->[0]);
    my @e = $feed->entries;
    my $summary = $e[0]->summary;
    ok(ref $summary eq 'XML::Atom::Syndication::Text');
    ok($summary->body eq $s->[1]);    
    ok($summary->type eq $s->[2]) if $s->[2];
}

1;