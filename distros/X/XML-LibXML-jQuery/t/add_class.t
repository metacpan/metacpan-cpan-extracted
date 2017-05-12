#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;


my $html = '<div class="container"><div class="foo"></div><div class="bar"></div></div>';


is j($html)->find('.foo, .bar')->add_class('nice')->as_html, '<div class="foo nice"></div><div class="bar nice"></div>';

is j($html)->find('.foo')->add_class('so nice')->add_class('so good foo')->attr('class'), 'foo so nice good', 'no duplicates';

is j($html)->find('.foo, .bar')->add_class(sub{
    my ($i, $oldclass) = @_;
    $_->tagname." $oldclass-$i"
})->as_html, '<div class="foo div foo-0"></div><div class="bar div bar-1"></div>', 'add_class(function)';

is j($html)->document->add_class('foo')->size, 1, 'skips non-element node';

done_testing;
