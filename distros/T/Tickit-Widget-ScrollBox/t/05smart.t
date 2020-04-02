#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;

use Tickit::Test;

use Tickit::Widget::ScrollBox;

my $win = mk_window;

my ( $vextent, $hextent );
my ( $downward, $rightward ) = (0) x 2;
{
   package ScrollableWidget;
   use base qw( Tickit::Widget );

   use constant CAN_SCROLL => 1;
   use constant WIDGET_PEN_FROM_STYLE => 1;

   sub lines { 1 }
   sub cols  { 1 }

   sub set_scrolling_extents
   {
      shift;
      ( $vextent, $hextent ) = @_;
      $vextent->set_total( 100 );
      $hextent->set_total(  50 )
   }

   sub scrolled
   {
      shift;
      $downward  += $_[0];
      $rightward += $_[1];
   }

   sub render_to_rb {}
}

my $child = ScrollableWidget->new;

my $widget = Tickit::Widget::ScrollBox->new(
   horizontal => 1,
   vertical   => 1,
)->set_child( $child );

$widget->set_window( $win );
flush_tickit;

ok( defined $vextent, '$vextent set' );
ok( defined $hextent, '$hextent set' );

ok( defined $child->window, '$child has window after $widget->set_window' );

is( $child->window->top,    0, '$child window starts on line 0' );
is( $child->window->left,   0, '$child window starts on column 0' );
is( $child->window->lines, 25, '$child given 25 line window' );
is( $child->window->cols,  79, '$child given 79 column window' );

is_display( [ [ BLANK(79), TEXT(" ",rv=>1)],
              ([BLANK(79), TEXT(" ",bg=>4)]) x 6,
              ([BLANK(79), TEXT("║",fg=>4)]) x 17,
              [ BLANK(79), TEXT("▾",rv=>1)] ],
            'Display initially' );

$widget->scroll( +10 );
flush_tickit;

is( $downward, 10, '$child informed of scroll +10' );
$downward = 0;

is( $child->window->top, 0, '$child window still starts on line 0 after scroll +10' );

$widget->scroll_to( 25 );
flush_tickit;

is( $downward, 15, '$child informed of scroll_to 25' );

is( $child->window->top, 0, '$child window still starts on line 0 after scroll_to 25' );

is_display( [ [ BLANK(79), TEXT("▴",rv=>1)],
              ([BLANK(79), TEXT("║",fg=>4)]) x 6,
              ([BLANK(79), TEXT(" ",bg=>4)]) x 6,
              ([BLANK(79), TEXT("║",fg=>4)]) x 11,
              [ BLANK(79), TEXT("▾",rv=>1)] ],
            'Display after scrolls' );

$vextent->set_total( 50 );
flush_tickit;

is_display( [ [ BLANK(79), TEXT("▴",rv=>1)],
              ([BLANK(79), TEXT("║",fg=>4)]) x 12,
              ([BLANK(79), TEXT(" ",bg=>4)]) x 11,
              [ BLANK(79), TEXT(" ",rv=>1)] ],
            'Display after ->set_total 50' );

done_testing;
