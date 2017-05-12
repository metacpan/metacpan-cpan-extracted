#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;



my $html = '<div class="container"><h2>Greetings</h2><div class="inner">Hello</div><div class="inner">Goodbye</div></div>';


is j($html)->contents->as_html, '<h2>Greetings</h2><div class="inner">Hello</div><div class="inner">Goodbye</div>', 'contents';
is j($html)->contents->end->as_html, $html, 'end';


done_testing;
