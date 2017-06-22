#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

my ( $term, $rootwin ) = mk_term_and_window;

ok( !$term->cursorvis, 'Cursor not yet visible initially' );

my $win = $rootwin->make_sub( 3, 10, 4, 20 );
flush_tickit;

my $focused;
my $bind_id = $win->bind_event( focus => sub {
   my ( $win, undef, $info ) = @_;
   $focused = $info->type("newapi");
   1;
} );

ok( !$win->is_focused, '$win->is_focused initially false' );
is( $focused, undef, '$focused not yet defined' );

$win->cursor_at( 0, 0 );
flush_tickit;

ok( !$win->is_focused, '$win->is_focused still false after ->cursor_at' );

$win->take_focus;

ok( $win->is_focused, '$win->is_focused true after ->take_focus' );
is( $focused, "in", '$focused is "in" after ->take_focus' );

flush_tickit;

is_termlog( [ GOTO(3,10), ],
            'Termlog initially' );

ok( $term->cursorvis, 'Cursor is visible after window focus' );

$win->reposition( 5, 15 );
flush_tickit;

is_termlog( [ GOTO(5,15), ],
            'Termlog after window reposition' );

$win->cursor_at( 2, 2 );
flush_tickit;

is_termlog( [ GOTO(7,17), ],
            'Termlog after ->cursor_at moves cursor' );

$win->cursor_shape( 2 );
flush_tickit;

is_termlog( [ GOTO(7,17), ],
            'Termlog after ->cursor_shape' );
is( $term->cursorshape, 2, 'Cursor shape after ->cursor_shape' );

$win->cursor_visible( 0 );
flush_tickit;

is_termlog( [ ],
            'Termlog empty after ->cursor_visible 0' );

ok( !$term->cursorvis, 'Cursor is invisible after ->cursor_visible 0' );

$win->cursor_visible( 1 );

$win->hide;
flush_tickit;

ok( !$term->cursorvis, 'Cursor is invisible after focus window hide' );

is_termlog( [ ],
            'Termlog empty after focus window hide' );

$win->show;
flush_tickit;

ok( $term->cursorvis, 'Cursor is visible after focus window show' );

is_termlog( [ GOTO(7,17), ],
            'Termlog after focus window show' );

# obscuring by child
{
   my $child = $win->make_sub( 1, 1, 4, 4 );
   flush_tickit;

   ok( !$term->cursorvis, 'Cursor is invisible after covering by child window' );

   $child->hide;
   flush_tickit;

   ok( $term->cursorvis, 'Cursor is visible after covering child is hidden' );

   $child->close;
   flush_tickit;
   drain_termlog;
}

# obscuring by sibling
{
   my $sib = $rootwin->make_sub( 6, 0, 2, 40 );
   $sib->raise;
   flush_tickit;

   ok( !$term->cursorvis, 'Cursor is invisible after covering by sibling window' );

   $sib->lower;
   flush_tickit;

   ok( $term->cursorvis, 'Cursor is visible again after lowering sibling window' );

   $sib->close;
   flush_tickit;
   drain_termlog;
}

{
   my $winA = $rootwin->make_sub( 5, 0, 1, 80 );
   my $winB = $rootwin->make_sub( 6, 0, 1, 80 );
   $winA->cursor_at( 0, 0 );
   $winB->cursor_at( 0, 0 );

   my $focusA; $winA->bind_event( focus => sub {
      my ( $win, undef, $info ) = @_;
      $focusA = $info->type("newapi");
      1;
   } );
   my $focusB; $winB->bind_event( focus => sub {
      my ( $win, undef, $info ) = @_;
      $focusB = $info->type("newapi");
      1;
   } );

   $winA->take_focus;
   flush_tickit;

   is( $focusA, "in", '$focusA after $winA->take_focus' );
   ok( !$focusB, '$focusB after $winA->take_focus' );
   is_termlog( [ GOTO(5,0) ],
               'Termlog after $winA->take_focus' );

   $winB->take_focus;
   flush_tickit;

   is( $focusA, "out", '$focusA after $winB->take_focus' );
   is( $focusB, "in",  '$focusB after $winB->take_focus' );
   is_termlog( [ GOTO(6,0) ],
               'Termlog after $winB->take_focus' );

   $winB->hide;
   $winA->take_focus;
   flush_tickit;

   is_termlog( [ GOTO(5,0) ],
               'Termlog after $winB hidden' );

   $winA->hide;
   $winB->show;
   flush_tickit;

   is_termlog( [ GOTO(6,0) ],
               'Termlog after $winA hidden/$winB shown' );

   $winA->take_focus;
   flush_tickit;

   is_termlog( [],
               'Termlog after ->take_focus on hidden window' );
   ok( $winB->is_focused, '$winB still has focus after ->take_focus on hidden window' );

   $winA->close;
   $winB->close;
   flush_tickit;
}

{
   my $otherwin = $rootwin->make_sub( 10, 5, 2, 2 );
   $otherwin->focus( 0, 0 );
   flush_tickit;

   ok( !$win->is_focused, '$win->is_focused false after ->focus on other window' );
   is( $focused, "out", '$focused is "out" after ->focus on other window' );

   $otherwin->close;
   flush_tickit;
}

{
   my $subwin = $win->make_sub( 1, 1, 2, 2 );
   $win->unbind_event_id( $bind_id );

   my @events;
   $bind_id = $win->bind_event( focus => sub {
      my ( $win, undef, $info ) = @_;
      push @events, [ win => $info->type("newapi"), $info->win ];
      1;
   } );
   $subwin->bind_event( focus => sub {
      my ( $win, undef, $info ) = @_;
      push @events, [ sub => $info->type("newapi") ];
      1;
   } );
   $win->set_focus_child_notify( 1 );
   flush_tickit;

   $subwin->focus( 0, 0 );

   is_deeply( \@events,
              [ [ win => "in", $subwin ], [ sub => "in" ] ],
              'Parent and child window both informed of focus in with focus_child_notify' );

   my $otherwin = $rootwin->make_sub( 0, 0, 1, 1 );
   flush_tickit;

   undef @events;

   $otherwin->focus( 0, 0 );

   is_deeply( \@events,
              [ [ sub => "out" ], [ win => "out", $subwin ] ],
              'Child and parent window both informed of focus out with focus_child_notify' );

   $subwin->close;
   $otherwin->close;
   flush_tickit;
}

done_testing;
