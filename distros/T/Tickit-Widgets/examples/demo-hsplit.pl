#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( HSplit Static );

my $hsplit = Tickit::Widget::HSplit->new(
   top_child => Tickit::Widget::Static->new(
      text => "Top child",
      align => "centre", valign => "middle",
   ),
   bottom_child => Tickit::Widget::Static->new(
      text => "Bottom child",
      align => "centre", valign => "middle",
   ),
);

Tickit->new( root => $hsplit )->run;
