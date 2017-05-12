#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;


sub test (&@);
my $html = '<div class="container"><h2>Greetings</h2><div class="inner">Hello</div><div class="inner">Goodbye</div></div>';


test { $_->new('<p/>')->insert_after($_->find('h2, .inner')->{nodes}) } 'insert_after(arrayref)';

test { $_->new('<p/>')->insert_after($_->find('.inner')->add('h2')) } 'insert_after(jQuery)';

test { $_->new('<p/>')->insert_after('h2, .inner') } 'insert_after(selector)';

test { $_->find('h2')->insert_after('.inner:last-child') }
     'insert_after(selector) (move)',
     '<div class="container"><div class="inner">Hello</div><div class="inner">Goodbye</div><h2>Greetings</h2></div>';

test { $_->find('h2')->insert_after($_->find('.inner:last-child')->get(0)) }
     'insert_after(element)',
     '<div class="container"><div class="inner">Hello</div><div class="inner">Goodbye</div><h2>Greetings</h2></div>';


done_testing;




sub test (&@) {
    my ($cb, $name, $expected) = @_;

    $expected ||= '<div class="container"><h2>Greetings</h2><p></p><div class="inner">Hello</div><p></p><div class="inner">Goodbye</div><p></p></div>';
    my $j = j($html);
    local $_ = $j;
    $cb->($j);
    is $j->as_html, $expected, $name;
}
