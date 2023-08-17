#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000148;

use Tickit::Test;

use Tickit::Widget;

my ( $term, $rootwin ) = mk_term_and_window;

my @widgets = map { TestWidget->new } 1 .. 2;

my @win;
$widgets[$_]->set_window( $win[$_] = $rootwin->make_sub( $_, 0, 1, 80 ) ) for 0 .. $#widgets;
flush_tickit;

is_termlog( [],
            'Termlog empty initially' );

is( $widgets[0]->pen->getattr( 'b' ), undef, '$widget pen b false before ->take_focus' );

$widgets[0]->take_focus;
flush_tickit;

ok( $win[0]->is_focused, '$win[0]->is_focused after ->take_focus' );

is_termlog( [ GOTO(0,2) ],
            'Termlog after ->take_focus' );

is( $widgets[0]->pen->getattr( 'b' ), 1, '$widget pen b true after ->take_focus' );

pressmouse( press => 1, 1, 20 );
flush_tickit;

ok( !$win[0]->is_focused, '$win[0]->is_focused false after mouse press' );
ok(  $win[1]->is_focused, '$win[1]->is_focused after mouse press' );

is_termlog( [ GOTO(1,2) ],
            'Termlog after mouse press' );

done_testing;

use Object::Pad;
class TestWidget :isa(Tickit::Widget) {
   use Tickit::Style;

   BEGIN {
      style_definition ':focus' =>
         b => 1;
   }

   use constant WIDGET_PEN_FROM_STYLE => 1;

   use constant CAN_FOCUS => 1;

   method render_to_rb {}

   method lines  { 1 }
   method cols   { 1 }

   method window_gained
   {
      my ( $win ) = @_;
      $self->SUPER::window_gained( @_ );

      $win->cursor_at( 0, 2 );
   }
}
