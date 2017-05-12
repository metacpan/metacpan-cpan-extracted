#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;



my $html = '<div class="container"><h2>Foo</h2><div class="inner">Hello</div><div class="inner">Goodbye</div></div>';

is j($html)->find('.inner')->append('<p>Test</p>')->end->as_html,
    '<div class="container"><h2>Foo</h2><div class="inner">Hello<p>Test</p></div><div class="inner">Goodbye<p>Test</p></div></div>', 'append content';

like j($html)->document->append('<p>Test</p>')->as_html, qr!<div class="inner">Goodbye</div>\s*</div><p>Test</p>!, 'apppend on document node';

# append existing element
my $j = j($html);
is $j->find('.inner')->append($j->find('h2'))->end->as_html, '<div class="container"><div class="inner">Hello<h2>Foo</h2></div><div class="inner">Goodbye<h2>Foo</h2></div></div>', 'append existing element';



done_testing;
