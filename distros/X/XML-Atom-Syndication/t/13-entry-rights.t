#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 19;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @rights = (
    ['entry_rights.xml','Example Atom'],
    ['entry_rights_escaped_markup.xml','Example <b>Atom</b>','html'],
    ['entry_rights_inline_markup_2.xml','History of the &lt;blink&gt; tag','xhtml'],
    ['entry_rights_inline_markup.xml','Example <b>Atom</b>','xhtml'],
    ['entry_rights_text_plain.xml','Example Atom','text'],
    ['entry_rights_text_plain_brackets.xml','History of the <blink> tag','text'],
    ['entry_rights_content_value.xml','Example Atom']
);

foreach my $r (@rights) {
    my $feed = get_feed($r->[0]);
    my @e = $feed->entries;
    my $rights = $e[0]->rights;
    ok(ref $rights eq 'XML::Atom::Syndication::Text');
    ok($rights->body eq $r->[1]);    
    ok($rights->type eq $r->[2]) if $r->[2];
}

1;