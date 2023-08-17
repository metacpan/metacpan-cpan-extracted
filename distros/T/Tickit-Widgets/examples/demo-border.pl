#!/usr/bin/perl

use v5.20;
use warnings;

use Tickit;
use Tickit::Widgets qw( Border Static );

my $border = Tickit::Widget::Border->new(
   h_border => 4, v_border => 2,
   style => { bg => "green" },
)
   ->set_child( Tickit::Widget::Static->new(
      text => "Hello, world!",
      align => "centre", valign => "middle",
      style => { bg => "black" },
   ) );

Tickit->new( root => $border )->run;
