#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Tickit::Test;

my $rootwin = mk_window;

# dragging within one window
{
   my @mouse_events;
   my $bind_id = $rootwin->bind_event( mouse => sub {
      my ( $win, undef, $info ) = @_;
      push @mouse_events, [ $info->type => $info->button, $info->line, $info->col ];
      return 1;
   } );


   # press
   pressmouse( press => 1, 2, 5 );

   is_deeply( \@mouse_events,
           [ [ press => 1, 2, 5 ] ],
           'mouse_events after press' );
   undef @mouse_events;

   # drag
   pressmouse( drag => 1, 3, 5 );

   is_deeply( \@mouse_events,
           [ [ drag_start => 1, 2, 5 ],
             [ drag       => 1, 3, 5 ] ],
           'mouse_events after drag contains drag_start' );
   undef @mouse_events;

   # release
   pressmouse( release => 1, 3, 5 );

   is_deeply( \@mouse_events,
           [ [ drag_drop => 1, 3, 5 ],
             [ drag_stop => 1, 3, 5 ],
             [ release   => 1, 3, 5 ] ],
           'mouse_events after release contains drag_drop and drag_stop' );
   undef @mouse_events;

   $rootwin->unbind_event_id( $bind_id );
}

# dragging between windows
{
   my $winA = $rootwin->make_sub(  0, 0, 10, 80 );
   my $winB = $rootwin->make_sub( 15, 0, 10, 80 );

   my @eventsA; $winA->bind_event( mouse => sub {
      my ( $win, undef, $info ) = @_;
      push @eventsA, [ $info->type => $info->button, $info->line, $info->col ];
      return 1;
   });
   my @eventsB; $winB->bind_event( mouse => sub {
      my ( $win, undef, $info ) = @_;
      push @eventsB, [ $info->type => $info->button, $info->line, $info->col ];
      return 1;
   });

   flush_tickit;

   pressmouse( press   => 1,  5, 20 );
   pressmouse( drag    => 1,  8, 20 );
   pressmouse( drag    => 1, 12, 20 );
   pressmouse( drag    => 1, 18, 20 );
   pressmouse( release => 1, 18, 20 );

   is_deeply( \@eventsA,
              [ [ press        => 1,  5, 20 ],
                [ drag_start   => 1,  5, 20 ],
                [ drag         => 1,  8, 20 ],
                [ drag_outside => 1, 12, 20 ],
                [ drag_outside => 1, 18, 20 ],
                [ drag_stop    => 1, 18, 20 ] ],
              'mouse events to window A after drag/drop operation' );

   is_deeply( \@eventsB,
              [ [ drag         => 1,  3, 20 ],
                [ drag_drop    => 1,  3, 20 ],
                [ release      => 1,  3, 20 ] ],
              'mouse events to window B after drag/drop operation' );

   $winA->close;
   $winB->close;
}

done_testing;
