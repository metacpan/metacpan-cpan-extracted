#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;


sub test(&@);

my $html = '<div class="container"><h2>Greetings</h2><div class="inner">Hello</div><div class="inner">Goodbye</div></div>';

# before(html)
test {  $_->find('h2, .inner')->before('<p/>')  } 'before(html)';

test {  $_->find('h2, .inner')->before(j('<p/>'))  } 'before(jQuery)';

test {
    my $p = $_->new('<p/>')->append_to($_);
    $_->find('h2, .inner')->before($p);
} 'before(jQuery) (existing node)';

test { $_->find('.inner')->before( j('<one/>'), '<two/>', $_->{document}->createElement('three')) }
    'before(jQuery, html, DOMElement)',
    '<div class="container"><h2>Greetings</h2><one></one><two></two><three></three><div class="inner">Hello</div><one></one><two></two><three></three><div class="inner">Goodbye</div></div>';

test {

    $_->find('.inner')->before(sub {
        my $i = shift;
        sprintf "<%s-%s>", lc $_->textContent, $i;
    })

} 'before(function)' => '<div class="container"><h2>Greetings</h2><hello-0></hello-0><div class="inner">Hello</div><goodbye-1></goodbye-1><div class="inner">Goodbye</div></div>';


subtest 'root nodes' => sub {

    # document
    my $j = j('<div/><div/><div/>');
    j($j->get(0))->before('<span/>');
    is $j->document->as_html, "<span></span><div></div><div></div><div></div>\n", 'on root node - node is first child';

    # document
    $j = j('<foo/><bar/><baz/>');
    j($j->get(1))->before('<span/>');
    is $j->document->as_html, "<foo></foo><span></span><bar></bar><baz></baz>\n", 'on root node - not first child';

    # document
    is j('<foo/><bar/><baz/>')->before('<span/>')->document->as_html, "<span></span><foo></foo><span></span><bar></bar><span></span><baz></baz>\n", 'on multiple root node';

};





sub test (&@) {
    my ($cb, $name, $expected) = @_;

    $expected ||= '<div class="container"><p></p><h2>Greetings</h2><p></p><div class="inner">Hello</div><p></p><div class="inner">Goodbye</div></div>';
    my $j = j($html);
    local $_ = $j;
    $cb->($j);
    is $j->as_html, $expected, $name;
}

done_testing;
