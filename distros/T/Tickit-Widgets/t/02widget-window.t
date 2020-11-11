#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Identity;
use Test::Refcount;

use Tickit::Test;

use Tickit::Widget;

my $win = mk_window;

my $gained_window;
my $lost_window;
my $render_rect;
my $widget = TestWidget->new;

is_oneref( $widget, '$widget has refcount 1 initially' );

identical( $widget->window, undef, '$widget->window initally' );

$widget->set_window( $win );

flush_tickit;

identical( $widget->window, $win, '$widget->window after set_window' );

identical( $gained_window, $win, '$widget->window_gained called' );

is( $render_rect,
    Tickit::Rect->new( top => 0, left => 0, lines => 25, cols => 80 ),
    '$rect to ->render_to_rb method' );

is_display( [ [TEXT("Hello")] ],
            'Display initially' );

$widget->set_window( undef );

identical( $lost_window, $win, '$widget->window_lost called' );

is_oneref( $widget, '$widget has refcount 1 at EOF' );

done_testing;

use Object::Pad 0.09;
class TestWidget extends Tickit::Widget {
   use constant WIDGET_PEN_FROM_STYLE => 1;

   method render_to_rb
   {
      ( my $rb, $render_rect ) = @_;

      $rb->text_at( 0, 0, "Hello" );
   }

   method lines { 1 }
   method cols  { 5 }

   method window_gained
   {
      ( $gained_window ) = @_;
      $self->SUPER::window_gained( @_ );
   }

   method window_lost
   {
      ( $lost_window ) = @_;
      $self->SUPER::window_lost( @_ );
   }
}
