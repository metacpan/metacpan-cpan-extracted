#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;



my $source =  '<div class="container"><div class="first"></div><div class="second"></div><div class="third"></div></div>';

is j($source)->find('div')->remove_attr('class')->as_html, '<div></div><div></div><div></div>';

is j($source)->find('div')->first
                          ->attr({ foo => 1, bar => 2, baz => 3 })
                          ->remove_attr(' class bar  baz ')->as_html, '<div foo="1"></div>';

is j($source)->document->remove_attr('foo')->size, 1, 'skips non-element node';

done_testing;
