#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;

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

package TestWidget;

use base qw( Tickit::Widget );
use Tickit::Style;

BEGIN {
   style_definition ':focus' =>
      b => 1;
}

use constant WIDGET_PEN_FROM_STYLE => 1;

use constant CAN_FOCUS => 1;

sub render_to_rb {}

sub lines  { 1 }
sub cols   { 1 }

sub window_gained
{
   my $self = shift;
   my ( $win ) = @_;
   $self->SUPER::window_gained( @_ );

   $win->cursor_at( 0, 2 );
}
