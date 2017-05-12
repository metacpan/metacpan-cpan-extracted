#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widget::Static;

use Tickit::Widget::VBox;
use Tickit::Widget::HBox;

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );
my $hbox;

$vbox->add( Tickit::Widget::Static->new( text => "ANSI" ) );
$vbox->add( $hbox = Tickit::Widget::HBox->new );
foreach my $col ( 0 .. 15 ) {
   $hbox->add( Tickit::Widget::Static->new(
      text => sprintf( "[%02d]", $col ),
      bg   => $col,
   ) );
}

$vbox->add( Tickit::Widget::Static->new( text => "216 RGB cube" ) );
$vbox->add( my $vbox256 = Tickit::Widget::VBox->new );
foreach my $y ( 0 .. 5 ) {
   $vbox256->add( $hbox = Tickit::Widget::HBox->new );
   foreach my $x ( 0 .. 35 ) {
      my $col = $y * 36 + $x + 16;
      $hbox->add( Tickit::Widget::Static->new(
         text => "  ",
         bg   => $col,
      ) );
   }
}

$vbox->add( Tickit::Widget::Static->new( text => "24 Greyscale ramp" ) );
$vbox->add( $hbox = Tickit::Widget::HBox->new );
foreach my $g ( 0 .. 23 ) {
   $hbox->add( Tickit::Widget::Static->new(
      text => sprintf( "g%02d", $g ),
      bg   => $g + 232,
      fg   => ( $g > 12 ) ? 0 : 7,
   ) );
}

Tickit->new( root => $vbox )->run;
