#!/usr/bin/perl

use v5.20;
use warnings;

use Tickit;
use Tickit::Widgets qw( VSplit Static );

my $vsplit = Tickit::Widget::VSplit->new
   ->set_left_child (Tickit::Widget::Static->new(
      text => "Left child",
      align => "centre", valign => "middle",
   ) )
   ->set_right_child( Tickit::Widget::Static->new(
      text => "Right child",
      align => "centre", valign => "middle",
   ) );

Tickit->new( root => $vsplit )->run;
