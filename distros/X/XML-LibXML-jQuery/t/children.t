#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;


my $html = <<HTML;
<div class="container">
    <div class="foo"><div class="bar">grandchildren</div></div>
    <div class="bar">children</div>
</div>
HTML

is j($html)->children->size, 2, 'children()';
is j($html)->children('.bar')->size, 1, 'chilren(selector)';
is j($html)->children('.bar')->as_html, '<div class="bar">children</div>', 'chilren(selector)';

is j($html)->document->children('div')->size, 1, 'on document';

done_testing;
