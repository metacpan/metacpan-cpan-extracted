#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Layout::Relative;
use Tickit::Widget::Static;

my $l = Tickit::Widget::Layout::Relative->new(width => 80, height => 45);
$l->add(
 Tickit::Widget::Static->new(text => 'text here'),
 title  => 'Little panel',
 id     => 'send',
 border => 'round dashed single',
 width  => '33%',
 height => '5em',
);
$l->add(
 Tickit::Widget::Static->new(text => 'text here'),
 title     => 'Another panel',
 id        => 'listen',
 below     => 'send',
 top_align => 'send',
 border    => 'round dashed single',
 width     => '33%',
 height    => '10em',
);
$l->add(
 Tickit::Widget::Static->new(text => 'text here'),
 title        => 'Something on the right',
 id           => 'overview',
 right_of     => 'listen',
 bottom_align => 'listen',
 margin_top   => '1em',
 margin_right => '3em',
);
Tickit->new(root => $l)->run;
