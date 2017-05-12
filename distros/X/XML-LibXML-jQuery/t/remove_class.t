#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;




my $html = '<div class="container"><div class="foo baz"></div><div class="foo bar baz"></div></div>';


is j($html)->find('.foo, .bar')->remove_class('foo baz')->as_html, '<div></div><div class="bar"></div>', 'remove_class';

is j($html)->find('.foo, .bar')->remove_class(sub{
    my ($i, $oldclass) = @_;
    "foo baz";
})->as_html, '<div></div><div class="bar"></div>', 'remove_class(function)';

is j($html)->document->remove_class('foo')->size, 1, 'skips non-element node';

done_testing;
