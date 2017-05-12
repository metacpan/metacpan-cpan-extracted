#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;



my $html = '<div class="demo-container"><div class="box">Demonstration Box</div><ul><li>list item 1</li><li>list <strong>item</strong> 2</li></ul></div>';

is j($html)->text, 'Demonstration Boxlist item 1list item 2', 'get';

is j($html)->find('.box')->text('cafeina')->end->as_html, '<div class="demo-container"><div class="box">cafeina</div><ul><li>list item 1</li><li>list <strong>item</strong> 2</li></ul></div>', 'set';


done_testing;

