#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;


my $html = <<HTML;

<div class="container">
    <div class="foo">Hello</div>
    <div class="foo">Goodbye</div>
    <div class="empty">


    </div>


HTML

is j($html)->find('.foo')->size, 2;

is j($html)->find('.empty')->size, 1;

is j($html)->find('.empty')->children->size, 0;



done_testing;
