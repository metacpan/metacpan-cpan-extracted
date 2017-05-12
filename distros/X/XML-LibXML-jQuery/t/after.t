#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;


my $html = '<div class="container"><h2>Greetings</h2><div class="inner">Hello</div><div class="inner">Goodbye</div></div>';

# after(html)
subtest 'after(html)' => sub {

    my $j = j($html);
    $j->find('.inner')->after('<p>Test</p>');

    is $j->as_html, '<div class="container"><h2>Greetings</h2><div class="inner">Hello</div><p>Test</p><div class="inner">Goodbye</div><p>Test</p></div>';
};

subtest 'after(jQuery)' => sub {

    my $j = j($html);
    $j->find('.inner')->after(j('<p>Test</p>'));

    is $j->as_html, '<div class="container"><h2>Greetings</h2><div class="inner">Hello</div><p>Test</p><div class="inner">Goodbye</div><p>Test</p></div>';
};


subtest 'after(jQuery) (existing node)' => sub {

    my $j = j($html);
    $j->find('.inner')->after($j->find('h2'));

    is $j->as_html, '<div class="container"><div class="inner">Hello</div><h2>Greetings</h2><div class="inner">Goodbye</div><h2>Greetings</h2></div>';
};


subtest 'after(jQuery, html, DOMElement)' => sub {

    my $j = j($html);
    $j->find('.inner')->after(j('<one/>'), '<two/>', $j->{document}->createElement('three'));

    is $j->as_html, '<div class="container"><h2>Greetings</h2><div class="inner">Hello</div><one></one><two></two><three></three><div class="inner">Goodbye</div><one></one><two></two><three></three></div>';
};


subtest 'after(function)' => sub {

    my $j = j($html);
    $j->find('.inner')->after(sub {
        my $i = shift;
        sprintf "<%s-%s>", lc $_->textContent, $i;
    });

    is $j->as_html, '<div class="container"><h2>Greetings</h2><div class="inner">Hello</div><hello-0></hello-0><div class="inner">Goodbye</div><goodbye-1></goodbye-1></div>';
};


subtest 'document node' => sub {

    # document
    my $j = j('<div/><div/><div/>');
    j($j->get(2))->after('<span/>');
    is $j->document->as_html, "<div></div><div></div><div></div><span></span>\n",
        'on root node - node is last child';

    # document
    $j = j('<foo/><bar/><baz/>');
    j($j->get(1))->after('<span/>');
    is $j->document->as_html, "<foo></foo><bar></bar><span></span><baz></baz>\n",
        'on root node - not last child';

    # document
    is j('<foo/><bar/><baz/>')->after('<span/>', '<p/>')->document->as_html,
        "<foo></foo><span></span><p></p><bar></bar><span></span><p></p><baz></baz><span></span><p></p>\n",
        'on multiple root node';
};


done_testing;
