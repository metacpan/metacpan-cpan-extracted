#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;



my $html = '<div class="container"><h2>Foo</h2><div class="inner">Hello</div><div class="inner">Goodbye</div></div>';

is j($html)->find('.inner')->prepend('<p>Test</p>')->end->as_html,
    '<div class="container"><h2>Foo</h2><div class="inner"><p>Test</p>Hello</div><div class="inner"><p>Test</p>Goodbye</div></div>', 'new content';

like j($html)->document->prepend('<p>Test</p>')->as_html, qr!<p>Test</p><div class="container">!, 'on document node';


# append existing element
my $j = j($html);
is $j->find('.inner')->prepend($j->find('h2'))->end->as_html, '<div class="container"><div class="inner"><h2>Foo</h2>Hello</div><div class="inner"><h2>Foo</h2>Goodbye</div></div>', 'existing element';

# empty element
is j('<div/>')->prepend('<span/>')->as_html, '<div><span></span></div>', 'on empty element';

done_testing;
