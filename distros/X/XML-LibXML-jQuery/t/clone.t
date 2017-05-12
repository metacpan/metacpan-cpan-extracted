#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;


my $html = '<div class="container"><div class="foo">Hello</div><div class="bar">Goodbye</div></div>';

my $j = j($html);

is $j->find('.foo')->clone->append_to($j->find('.bar'))->end->end->as_html, '<div class="container"><div class="foo">Hello</div><div class="bar">Goodbye<div class="foo">Hello</div></div></div>';


done_testing;
