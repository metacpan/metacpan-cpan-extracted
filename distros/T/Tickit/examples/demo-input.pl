#!/usr/bin/perl

use v5.14;
use warnings;

use Tickit;

my $tickit = Tickit->new();
my $rootwin = $tickit->rootwin;

my $keywin = $rootwin->make_sub( 2, 2, 3, $rootwin->cols - 7 );
my $keyev;
$keywin->bind_event( expose => sub {
   my ( $win, undef, $info ) = @_;
   my $rb = $info->rb;

   $rb->eraserect( $info->rect );

   $rb->goto( 0, 0 );
   {
      $rb->savepen;
      $rb->setpen( Tickit::Pen->new( fg => 3, b => 1 ) );
      $rb->text( "Key:" );
      $rb->restore;
   }

   $keyev or return 1;

   $rb->goto( 2, 2 );
   $rb->text( sprintf "%s %s ",
      $keyev->type, $keyev->str );
   $rb->text( _modstr( $keyev->mod ) );

   return 1;
} );

my $mousewin = $rootwin->make_sub( 8, 2, 3, $rootwin->cols - 7 );
my $mouseev;
$mousewin->bind_event( expose => sub {
   my ( $win, undef, $info ) = @_;
   my $rb = $info->rb;

   $rb->eraserect( $info->rect );

   $rb->goto( 0, 0 );
   {
      $rb->savepen;
      $rb->setpen( Tickit::Pen->new( fg => 3, b => 1 ) );
      $rb->text( "Mouse:" );
      $rb->restore;
   }

   $mouseev or return 1;

   $rb->goto( 2, 2 );
   $rb->text( sprintf "%s button %s at (%d,%d) ",
      $mouseev->type, $mouseev->button, $mouseev->line, $mouseev->col );
   $rb->text( _modstr( $mouseev->mod ) );

   return 1;
} );

sub _modstr
{
   my ( $mod ) = @_;
   $mod or return "";

   return "<" . join( "|",
      ( $mod & 2 ? "ALT" : () ), ( $mod & 4 ? "CTRL" : () ), ( $mod & 1 ? "SHIFT" : () )
   ) . ">";
}

$rootwin->bind_event( key => sub {
   my ( undef, $ev, $info ) = @_;
   $keyev = $info;
   $keywin->expose;
   return 1;
} );

$rootwin->bind_event( mouse => sub {
   my ( undef, $ev, $info ) = @_;
   $mouseev = $info;
   $mousewin->expose;
   return 1;
} );

$rootwin->take_focus;

$tickit->run;
