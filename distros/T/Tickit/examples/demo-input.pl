#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widget::Static;

use Tickit::Widget::VBox;
use Tickit::Widget::HBox;

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );

my $keydisplay;
$vbox->add( Tickit::Widget::Static->new( text => "Key:" ) );
$vbox->add( $keydisplay = Tickit::Widget::Static->new( text => "" ) );

my $mousedisplay;
$vbox->add( Tickit::Widget::Static->new( text => "Mouse:" ) );
$vbox->add( $mousedisplay = Tickit::Widget::Static->new( text => "" ) );

my $tickit = Tickit->new();

sub _modstr
{
   my ( $mod ) = @_;
   return join "-", ( $mod & 2 ? "A" : () ), ( $mod & 4 ? "C" : () ), ( $mod & 1 ? "S" : () );
}

# Mass hackery
$tickit->term->bind_event( key => sub {
   my ( undef, $ev, $info ) = @_;
   $keydisplay->set_text( sprintf "%s %s (mod=%s)",
      $info->type, $info->str, _modstr( $info->mod )
   );
   return 1;
} );

$tickit->term->bind_event( mouse => sub {
   my ( undef, $ev, $info ) = @_;
   $mousedisplay->set_text( sprintf "%s button %s at (%d,%d) (mod=%s)",
      $info->type, $info->button, $info->line, $info->col, _modstr( $info->mod )
   );
   return 1;
} );

$tickit->set_root_widget( $vbox );

$tickit->run;
