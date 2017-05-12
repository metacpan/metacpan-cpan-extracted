#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;




my $html = '<div class="container"><div class="foo"><p></p></div><div class="bar"><p></p></div></div>';


is j($html)->find('p')->parent->as_html, '<div class="foo"><p></p></div><div class="bar"><p></p></div>';
is j($html)->find('p')->parent->size, 2, 'size';
is j($html)->find('p')->parent('div.foo')->size, 1, 'selector';
is j($html)->find('p')->parent('span')->size, 0, 'another selector';
is j($html)->document->parent->size, 0, 'no parent';


done_testing;

