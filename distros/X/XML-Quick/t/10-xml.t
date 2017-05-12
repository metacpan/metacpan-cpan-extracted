#!perl -T

use warnings;
use strict;

use Test::More;
use Test::XML;
use XML::Quick;

plan tests => 14;

my @tests = (
    { 'tag' => 'value' }                    => qq(<tag>value</tag>),

    { 'tag' => 'value',
      'tag2' => 'value2' }                  => qq(<tag>value</tag><tag2>value2</tag2>),

    { 'tag' =>
        [ 'one',
          'two',
          'three' ]}                        => qq(<tag>one</tag><tag>two</tag><tag>three</tag>),

    { 'tag' =>
        { 'subtag' => 'value' }}            => qq(<tag><subtag>value</subtag></tag>),

    { 'tag' => undef }                      => qq(<tag/>),

    { 'tag' =>
        { '_attrs' =>
            { 'foo' => 'bar' }}}            => qq(<tag foo="bar"/>),

    { 'tag' =>
        { '_attrs' =>
            { 'foo' => 'bar' },
          '_cdata' => 'value' }}            => qq(<tag foo="bar">value</tag>),

    { 'tag' =>
        { '_attrs' =>
            { 'foo' => 'bar' },
            'subtag' => 'value' }}          => qq(<tag foo="bar"><subtag>value</subtag></tag>),

    [ { 'tag' => 'value' },
      { root => 'wrap' } ]                  => qq(<wrap><tag>value</tag></wrap>),

    [ { 'tag' => 'value' },
      { root => 'wrap',
        attrs => { 'style' => 'shiny' }} ]  => qq(<wrap style="shiny"><tag>value</tag></wrap>),

    [ { 'tag' => 'value' },
      { root => 'wrap',
        cdata => 'tagging along' } ]        => qq(<wrap>tagging along<tag>value</tag></wrap>),

    [ '',
      { root => 'tag',
        cdata => 'value' } ]                => qq(<tag>value</tag>),

    [ "<xml>foo</xml>",
      { root => 'wrap' } ]                  => qq(<wrap>&lt;xml&gt;foo&lt;/xml&gt;</wrap>),

    [ "<xml>foo</xml>",
      { root => 'wrap',
        escape => 0 } ]                     => qq(<wrap><xml>foo</xml></wrap>),
);

while(@tests > 1) {
    my $in = shift @tests;
    my $out = shift @tests;

    if(ref $in eq "ARRAY") {
        is_xml(wrap(xml(@{$in})), wrap($out));
    }
    else {
        is_xml(wrap(xml($in)), wrap($out));
    }
}

diag("test set had leftover items, probable bug in $0") if @tests > 0;

sub wrap {
    return "<top>$_[0]</top>" if @_ > 0 and $_[0];
    return "<top/>";
}
