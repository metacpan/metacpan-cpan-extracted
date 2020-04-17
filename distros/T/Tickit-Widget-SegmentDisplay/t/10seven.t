#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;

use Tickit::Test;

use Tickit::Widget::SegmentDisplay;

my $root = mk_window;

my $win = $root->make_sub( 0, 0, 5, 8 );

# default style
{
   my $widget = Tickit::Widget::SegmentDisplay->new(
      value => 0,
      type  => "seven",
   );

   ok( defined $widget, 'defined $widget' );

   $widget->set_window( $win );
   flush_tickit;

   is_display( [
         [TEXT("  "), TEXT("    ",bg=>1), TEXT("  ")],
         [TEXT("  ",bg=>1), TEXT("    "), TEXT("  ",bg=>1)],
         [TEXT("  "), TEXT("    ",bg=>52), TEXT("  ")],
         [TEXT("  ",bg=>1), TEXT("    "), TEXT("  ",bg=>1)],
         [TEXT("  "), TEXT("    ",bg=>1), TEXT("  ")],
      ],
      'Display initially in default style' );

   $widget->set_value( 3 );
   flush_tickit;

   is_display( [
         [TEXT("  "), TEXT("    ",bg=>1), TEXT("  ")],
         [TEXT("  ",bg=>52), TEXT("    "), TEXT("  ",bg=>1)],
         [TEXT("  "), TEXT("    ",bg=>1), TEXT("  ")],
         [TEXT("  ",bg=>52), TEXT("    "), TEXT("  ",bg=>1)],
         [TEXT("  "), TEXT("    ",bg=>1), TEXT("  ")],
      ],
      'Display for value=3 in default style' );

   $widget->set_window( undef );
}

# halfline
{
   my $widget = Tickit::Widget::SegmentDisplay->new(
      value => 0,
      type  => "seven",
      use_halfline => 1,
   );

   $widget->set_window( $win );
   flush_tickit;

   is_display( [
         [TEXT("  "), TEXT("████",fg=>1), TEXT("  ")],
         [TEXT("██",fg=>1), TEXT("    "), TEXT("██",fg=>1)],
         [TEXT("  "), TEXT("████",fg=>52), TEXT("  ")],
         [TEXT("██",fg=>1), TEXT("    "), TEXT("██",fg=>1)],
         [TEXT("  "), TEXT("████",fg=>1), TEXT("  ")],
      ],
      'Display initially in halfline style' );

   $widget->set_window( undef );
}

# linedraw
{
   my $widget = Tickit::Widget::SegmentDisplay->new(
      value => 0,
      type  => "seven",
      use_linedraw => 1,
   );

   $widget->set_window( $win );
   flush_tickit;

   is_display( [
         [TEXT("┌──────┐",fg=>1)],
         [TEXT("│      │",fg=>1)],
         [TEXT("│      │",fg=>1)],
         [TEXT("│      │",fg=>1)],
         [TEXT("└──────┘",fg=>1)],
      ],
      'Display initially in halfline style' );

   $widget->set_window( undef );
}

done_testing;
