#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::ScrollBox;

my $win = mk_window;

my $static = Tickit::Widget::Static->new(
   text => join "\n", map { "X" x 200 } 1 .. 100
);

my $widget = Tickit::Widget::ScrollBox->new(
   horizontal => 1,
   vertical   => 1,
);

$widget->add( $static );
$widget->set_window( $win );

my $vextent = $widget->vextent;
my $hextent = $widget->hextent;

# We won't use the is_display tests here because they're annoying to write.
# Having asserted that the Extent objects do the right thing in earlier tests,
# we'll just check the input events have the right effect on those.

is( $vextent->start, 0, 'vextent start is 0 initially' );
is( $hextent->start, 0, 'hextent start is 0 initially' );

# vertical
{
   # down arrow
   pressmouse( press   => 1, 23, 79 );
   pressmouse( release => 1, 23, 79 );
   is( $vextent->start, 1, 'start moves down +1 after mouse click down arrow' );

   # 'after' area
   pressmouse( press   => 1, 21, 79 );
   pressmouse( release => 1, 21, 79 );
   is( $vextent->start, 13, 'start moves down +12 after mouse click after area' );

   # up arrow
   pressmouse( press   => 1, 0, 79 );
   pressmouse( release => 1, 0, 79 );
   is( $vextent->start, 12, 'start moves up -1 after mouse click up arrow' );

   # 'before' area
   pressmouse( press   => 1, 1, 79 );
   pressmouse( release => 1, 1, 79 );
   is( $vextent->start, 0, 'start moves up -12 after mouse click up arrow' );

   # click-drag
   pressmouse( press   => 1,  5, 79 );
   pressmouse( drag    => 1, 10, 79 );
   pressmouse( release => 1, 10, 79 );
   is( $vextent->start, 23, 'start is 22 after mouse drag' );

   # wheel - doesn't have to be in scrollbar
   pressmouse( wheel => 'down', 13, 40 );
   is( $vextent->start, 28, 'start moves down +5 after wheel down' );
   pressmouse( wheel => 'up',   13, 40 );
   is( $vextent->start, 23, 'start moves up -5 after wheel up' );
}

# horizontal
{
   # right arrow
   pressmouse( press   => 1, 24, 78 );
   pressmouse( release => 1, 24, 78 );
   is( $hextent->start, 1, 'start moves right +1 after mouse click right arrow' );

   # 'after' area
   pressmouse( press   => 1, 24, 72 );
   pressmouse( release => 1, 24, 72 );
   is( $hextent->start, 40, 'start moves right +39 after mouse click after area' );

   # left arrow
   pressmouse( press   => 1, 24, 0 );
   pressmouse( release => 1, 24, 0 );
   is( $hextent->start, 39, 'start moves left -1 after mouse click left arrow' );

   # 'before' area
   pressmouse( press   => 1, 24, 5 );
   pressmouse( release => 1, 24, 5 );
   is( $hextent->start, 0, 'start moves left -39 after mouse click before area' );

   # click-drag
   pressmouse( press   => 1, 24, 20 );
   pressmouse( drag    => 1, 24, 30 );
   pressmouse( release => 1, 24, 30 );
   is( $hextent->start, 26, 'start is 26 after mouse drag' );
}

done_testing;
