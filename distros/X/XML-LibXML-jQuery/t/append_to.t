#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;



my $html = '<div class="container"><h2>Foo</h2><div class="inner">Hello</div><div class="inner">Goodbye</div></div>';
my $j = j($html);
j('<p>Test</p>')->append_to($j->find('.inner'));

is $j->as_html,
    '<div class="container"><h2>Foo</h2><div class="inner">Hello<p>Test</p></div><div class="inner">Goodbye<p>Test</p></div></div>', 'append content';

# existing element
$j = j($html);
is $j->find('h2')->append_to($j->find('.inner'))->end->as_html, '<div class="container"><div class="inner">Hello<h2>Foo</h2></div><div class="inner">Goodbye<h2>Foo</h2></div></div>', 'existing element';



done_testing;
