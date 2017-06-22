#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Refcount;

use Tickit::Test;

my $root = mk_window;

my $rootfloat = $root->make_float( 10, 10, 5, 30 );
flush_tickit;

is_oneref( $rootfloat, '$rootfloat has refcount 1 initially' );
is_refcount( $root, 2, '$root has refcount 2 after ->make_float' );

{
   my $bind_id = $root->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      my $rb = $info->rb;
      my $rect = $info->rect;

      foreach my $line ( $rect->linerange ) {
         $rb->text_at( $line, $rect->left, "X" x $rect->cols );
      }
   });

   $root->expose( Tickit::Rect->new(
      top => 10, lines => 1, left => 0, cols => 80,
   ) );
   flush_tickit;

   is_termlog( [ GOTO(10,0),
                 SETPEN,
                 PRINT("X"x10),
                 GOTO(10,40),
                 SETPEN,
                 PRINT("X"x40) ],
               'Termlog for print under floating window' );

   is_display( [ BLANKLINES(10),
                 [TEXT("X"x10), BLANK(30), TEXT("X"x40)] ],
               'Display for print under floating window' );

   $root->unbind_event_id( $bind_id );
}

{
   my $win = $root->make_sub( 10, 20, 1, 50 );

   $win->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      $info->rb->text_at( 0, 0, "Y" x 50 );
   });

   $win->expose;
   flush_tickit;

   is_termlog( [ GOTO(10,40),
                 SETPEN,
                 PRINT("Y"x30) ],
               'Termlog for print sibling under floating window' );

   is_display( [ BLANKLINES(10),
                 [TEXT("X"x10), BLANK(30), TEXT("Y"x30), TEXT("X"x10)] ],
               'Display for print sibling under floating window' );

   my $popupwin = $win->make_popup( 2, 2, 10, 10 );
   flush_tickit;

   is_oneref( $popupwin, '$popupwin has refcount 1 initially' );

   identical( $popupwin->parent, $root, '$popupwin->parent is $root' );

   ok( $popupwin->is_steal_input, '$popupwin is stealing input events' );

   is( $popupwin->abs_top,  12, '$popupwin->abs_top' );
   is( $popupwin->abs_left, 22, '$popupwin->abs_left' );

   my @key_events;
   $popupwin->bind_event( key => sub {
      my ( $win, undef, $info ) = @_;
      push @key_events, [ $info->type => $info->str ];
      return 1;
   } );

   presskey( text => "G" );

   my @mouse_events;
   $popupwin->bind_event( mouse => sub {
      my ( $win, undef, $info ) = @_;
      push @mouse_events, [ $info->type => $info->button, $info->line, $info->col ];
      return 1;
   } );

   pressmouse( press => 1, 5, 12 );

   is_deeply( \@mouse_events, [ [ press => 1, -7, -10 ] ] );
   undef @mouse_events;

   $popupwin->set_steal_input( 0 );

   pressmouse( press => 1, 5, 12 );

   is( scalar @mouse_events, 0, '$popupwin does not steal input after disable' );

   $popupwin->close;
   $win->close;
   flush_tickit;
   drain_termlog;
}

my $bind_id = $rootfloat->bind_event( expose => sub {
   my ( $win, undef, $info ) = @_;
   $info->rb->text_at( 0, 0, "|-- Yipee --|" );
});
$rootfloat->expose;
flush_tickit;

is_termlog( [ GOTO(10,10),
              SETPEN,
              PRINT("|-- Yipee --|") ],
            'Termlog for print to floating window' );

is_display( [ BLANKLINES(10),
              [TEXT("X"x10), TEXT("|-- Yipee --|"), BLANK(17), TEXT("Y"x30), TEXT("X"x10)] ],
            'Display for print to floating window' );

my $subwin = $rootfloat->make_sub( 0, 4, 1, 6 );

$subwin->bind_event( expose => sub {
   my ( $win, undef, $info ) = @_;
   $info->rb->text_at( 0, 0, "Byenow" );
});
$subwin->expose;
flush_tickit;

is_termlog( [ GOTO(10,14),
              SETPEN,
              PRINT("Byenow") ],
            'Termlog for print to child of floating window' );

is_display( [ BLANKLINES(10),
              [TEXT("X"x10), TEXT("|-- Byenow--|"), BLANK(17), TEXT("Y"x30), TEXT("X"x10)] ],
            'Display for print to child of floating window' );

$rootfloat->unbind_event_id( $bind_id );

# Scrolling with float obscurations
{
   my @exposed_rects;
   my $bind_id = $root->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      push @exposed_rects, $info->rect;
   } );

   $root->scroll( 3, 0 );
   flush_tickit;

   is_termlog( [ SETPEN,
                 SCROLLRECT(0,0,10,80, 3,0),
                 SCROLLRECT(15,0,10,80, 3,0) ],
               'Termlog after scroll with floats' );

   is_deeply( \@exposed_rects,
              [ Tickit::Rect->new( top =>  7, left =>  0, lines => 3, cols => 80 ),
                Tickit::Rect->new( top => 10, left =>  0, lines => 5, cols => 10 ),
                Tickit::Rect->new( top => 10, left => 40, lines => 5, cols => 40 ),
                Tickit::Rect->new( top => 22, left =>  0, lines => 3, cols => 80 ), ],
              'Exposed regions after scroll with floats' );

   $root->unbind_event_id( $bind_id );
}

done_testing;
