#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;




my $html = '<div class="container"><div class="foo"><p></p></div><div class="bar"><p></p></div></div>';


is j($html)->find('div')->each(sub{
    my ($i, $el) = @_;
    $el->setAttribute('id', $i);
    $_->removeChildNodes;

})->end->as_html, '<div class="container"><div class="foo" id="0"></div><div class="bar" id="1"></div></div>';


is j('<div><p></p><p></p><p></p></div>')->find('p')->each(sub {
    my ($i, $el) = @_;
    $el->setAttribute('id', $i);
    return undef if $i == 1;
})->end->as_html, '<div><p id="0"></p><p id="1"></p><p></p></div>';


done_testing;
