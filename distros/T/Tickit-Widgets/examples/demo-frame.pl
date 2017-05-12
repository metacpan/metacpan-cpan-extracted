#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( Static VBox Frame );

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );

my $fg = 1;
foreach my $linetype ( qw( ascii single double thick solid_inside solid_outside ) ) {
   $vbox->add( Tickit::Widget::Frame->new(
      style => { 
         linetype => $linetype,
         frame_fg => $fg++,
      },
      child => Tickit::Widget::Static->new( text => $linetype, align => 0.5 )
   ) );
}

$vbox->add( Tickit::Widget::Frame->new(
   style => {
      linetype_top    => "double",
      linetype_bottom => "double",
      linetype_left   => "single",
      linetype_right  => "single",
   },
   child => Tickit::Widget::Static->new( text => "mixed lines", align => 0.5 )
) );

$vbox->add( Tickit::Widget::Frame->new(
   style => {
      linetype_top    => "double",
      linetype_bottom => "single",
      linetype_left   => "solid_outside",
      linetype_right  => "solid_outside",
   },
   child => Tickit::Widget::Static->new( text => "mixed", align => 0.5 )
) );

Tickit->new( root => $vbox )->run;
