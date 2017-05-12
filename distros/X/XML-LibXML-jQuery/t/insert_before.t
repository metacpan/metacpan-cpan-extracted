#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;



sub test (&@);
my $html = '<div class="container"><h2>Greetings</h2><div class="inner">Hello</div><div class="inner">Goodbye</div></div>';
my $expected = '<div class="container"><p></p><h2>Greetings</h2><p></p><div class="inner">Hello</div><p></p><div class="inner">Goodbye</div></div>';


test { $_->new('<p/>')->insert_before($_->find('h2, .inner')->{nodes}) } 'insert_before(arrayref)';

test { $_->new('<p/>')->insert_before($_->find('.inner')->add('h2')) } 'insert_before(jQuery)';

test { $_->new('<p/>')->insert_before('h2, .inner') } 'insert_before(selector)';


$expected = '<div class="container"><div class="inner">Hello</div><h2>Greetings</h2><div class="inner">Goodbye</div></div>';

test { $_->find('h2')->insert_before('.inner:last-child') } 'insert_before(selector) (move)';

test { $_->find('h2')->insert_before($_->find('.inner:last-child')->get(0)) } 'insert_before(element)';


done_testing;




sub test (&@) {
    my ($cb, $name) = @_;

    my $j = j($html);
    local $_ = $j;
    $cb->($j);
    is $j->as_html, $expected, $name;
}
