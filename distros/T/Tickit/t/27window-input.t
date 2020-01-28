#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

my $rootwin = mk_window;

my $win = $rootwin->make_sub( 3, 10, 4, 20 );

$win->focus( 0, 0 );
flush_tickit;

my $keyev;
my @key_events;
my $bind_id_key = $win->bind_event( key => sub {
   ( my $_win, undef, $keyev ) = @_;
   is( $_win, $win, '$win for key event' );
   push @key_events, [ $keyev->type => $keyev->str ];
   return 1;
} );

# Simple key events
{
   presskey( text => "A" );

   is_deeply( \@key_events, [ [ text => "A" ] ], 'on_key A' );

   ok( !$keyev->mod_is_shift, 'A key is not shift' );
   ok( !$keyev->mod_is_ctrl,  'A key is not ctrl' );
   ok( !$keyev->mod_is_alt,   'A key is not alt' );

   undef @key_events;

   presskey( key => "C-a", 4 );

   is_deeply( \@key_events, [ [ key => "C-a" ] ], 'on_key C-a' );

   ok( !$keyev->mod_is_shift, 'C-a key is not shift' );
   ok(  $keyev->mod_is_ctrl,  'C-a key is ctrl' );
   ok( !$keyev->mod_is_alt,   'C-a key is not alt' );
}

my @mouse_events;
my $bind_id_mouse = $win->bind_event( mouse => sub {
   my ( $win, undef, $info ) = @_;
   push @mouse_events, [ $info->type => $info->button, $info->line, $info->col ];
   return 1;
} );

# Simple mouse events
{
   undef @mouse_events;
   pressmouse( press => 1, 5, 15 );

   is_deeply( \@mouse_events, [ [ press => 1, 2, 5 ] ], 'on_mouse abs@15,5' );

   undef @mouse_events;
   pressmouse( press => 1, 1, 2 );

   is_deeply( \@mouse_events, [], 'no event for mouse abs@2,1' );
}

# Event passing to subwindows
{
   my $subwin = $win->make_sub( 2, 2, 1, 10 );

   $subwin->focus( 0, 0 );
   flush_tickit;

   my @subkey_events;
   my @submouse_events;
   my $subret = 1;
   $subwin->bind_event( key => sub {
      my ( $win, undef, $ev ) = @_;
      push @subkey_events, [ $ev->type => $ev->str ];
      return $subret;
   } );
   $subwin->bind_event( mouse => sub {
      my ( $win, undef, $ev ) = @_;
      push @submouse_events, [ $ev->type => $ev->button, $ev->line, $ev->col ];
      return $subret;
   } );

   undef @key_events;

   presskey( text => "B" );

   is_deeply( \@subkey_events, [ [ text => "B" ] ], 'on_key B on subwin' );
   is_deeply( \@key_events,    [ ],                 'on_key B on win' );

   undef @mouse_events;

   pressmouse( press => 1, 5, 15 );

   is_deeply( \@submouse_events, [ [ press => 1, 0, 3 ] ], 'on_mouse abs@15,5 on subwin' );
   is_deeply( \@mouse_events,    [ ],                      'on_mouse abs@15,5 on win' );

   $subret = 0;

   undef @key_events;
   undef @subkey_events;

   presskey( text => "C" );

   is_deeply( \@subkey_events, [ [ text => "C" ] ], 'on_key C on subwin' );
   is_deeply( \@key_events,    [ [ text => "C" ] ], 'on_key C on win' );

   undef @mouse_events;
   undef @submouse_events;

   pressmouse( press => 1, 5, 15 );

   is_deeply( \@submouse_events, [ [ press => 1, 0, 3 ] ], 'on_mouse abs@15,5 on subwin' );
   is_deeply( \@mouse_events,    [ [ press => 1, 2, 5 ] ], 'on_mouse abs@15,5 on win' );

   my $otherwin = $rootwin->make_sub( 10, 10, 4, 20 );
   flush_tickit;

   my @handlers;
   $win->unbind_event_id( $bind_id_key );
   $bind_id_key = $win->bind_event( key => sub { push @handlers, "win";      return 0 } );
   $subwin->bind_event            ( key => sub { push @handlers, "subwin";   return 0 } );
   $otherwin->bind_event          ( key => sub { push @handlers, "otherwin"; return 0 } );

   presskey( text => "D" );

   is_deeply( \@handlers, [qw( subwin win otherwin )], 'on_key D propagates to otherwin after win' );

   $subwin->hide;

   undef @handlers;

   presskey( text => "E" );

   is_deeply( \@handlers, [qw( win otherwin )], 'hidden windows do not receive input events' );

   $subwin->close;
   flush_tickit;
}

# Windows created in input event handlers don't receive events
{
   my $childwin;
   my $childmouse;
   $win->unbind_event_id( $bind_id_mouse );
   $bind_id_mouse = $win->bind_event( mouse => sub {
      return if $childwin;

      $childwin = $win->make_sub( 0, 0, 2, 2 );
      $childwin->bind_event( mouse => sub { $childmouse++ } );
   } );

   pressmouse( press => 1, 3, 10 );

   ok( defined $childwin, '$childwin created' );
   ok( !$childmouse,      '$childwin has not yet received mouse event' );

   flush_tickit;

   pressmouse( press => 1, 3, 10 );

   is( $childmouse, 1, '$childwin has now received a mouse event after flush' );

   $childwin->close;
   flush_tickit;
}

{
   my $sibwin;
   my $sibmouse;
   $win->unbind_event_id( $bind_id_mouse );
   $bind_id_mouse = $win->bind_event( mouse => sub {
      return if $sibwin;

      $sibwin = $win->make_float( 0, 0, 2, 2 );
      $sibwin->bind_event( mouse => sub { $sibmouse++ });
   } );

   pressmouse( press => 1, 3, 10 );

   ok( defined $sibwin, '$sibwin created' );
   ok( !$sibmouse,      '$sibwin has not yet received mouse event' );

   flush_tickit;

   pressmouse( press => 1, 3, 10 );

   is( $sibmouse, 1, '$sibwin has now received a mouse event after flush' );

   $sibwin->close;
   flush_tickit;
}

done_testing;
