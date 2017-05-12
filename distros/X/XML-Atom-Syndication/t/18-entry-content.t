#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 22;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @contents = (
    ['entry_content_application_xml.xml','body','Example <b>Atom</b>'],
    ['entry_content_base64.xml','body','Example <b>Atom</b>'],
    ['entry_content_base64_2.xml','body','<p>History of the &lt;blink&gt; tag</p>'],
    ['entry_content_escaped_markup.xml','body','Example <b>Atom</b>'],
    ['entry_content_inline_markup.xml','body','Example <b>Atom</b>'],
    ['entry_content_inline_markup_2.xml','body','<![CDATA[History of the <blink> tag]]>'],
    ['entry_content_src.xml','src','http://example.com/movie.mp4'],
    ['entry_content_text_plain.xml','body','Example Atom'],
    ['entry_content_text_plain_brackets.xml','body','History of the <blink> tag'],
    ['entry_content_type_text.xml','type','text'],
    ['entry_content_value.xml','body','Example Atom']
);

foreach my $c (@contents) {
    my $feed = get_feed($c->[0]);
    my @e = $feed->entries;
    my $content = $e[0]->content;
    my $meth = $c->[1];
    ok(ref $content eq 'XML::Atom::Syndication::Content');
    ok($content->$meth eq $c->[2]);
}

1;