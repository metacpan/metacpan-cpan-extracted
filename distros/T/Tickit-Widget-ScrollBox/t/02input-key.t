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

is( $vextent->start, 0, 'start is 0 initially' );
is( $hextent->start, 0, 'hextent start is 0 initially' );

# vertical
{
   presskey( key => "Down" );
   is( $vextent->start, 1, 'start moves down +1 after <Down>' );

   presskey( key => "PageDown" );
   is( $vextent->start, 13, 'start moves down +12 after <PageDown>' );

   presskey( key => "Up" );
   is( $vextent->start, 12, 'start moves up -1 after <Up>' );

   presskey( key => "PageUp" );
   is( $vextent->start, 0, 'start moves up -12 after <PageUp>' );

   presskey( key => "C-End", 0x04 );
   is( $vextent->start, 76, 'start moves to 76 after <C-End>' );

   presskey( key => "C-Home", 0x04 );
   is( $vextent->start, 0, 'start moves to 0 after <C-Home>' );
}

# horizontal
{
   presskey( key => "Right" );
   is( $hextent->start, 1, 'start moves right +1 after <Right>' );

   presskey( key => "C-Right", 0x4 );
   is( $hextent->start, 40, 'start moves right +39 after <C-Right>' );

   presskey( key => "Left" );
   is( $hextent->start, 39, 'start moves up -1 after <Left>' );

   presskey( key => "C-Left", 0x4 );
   is( $hextent->start, 0, 'start moves up -39 after <C-Left>' );

   presskey( key => "End" );
   is( $hextent->start, 121, 'start moves to 121 after <End>' );

   presskey( key => "Home" );
   is( $hextent->start, 0, 'start moves to 0 after <Home>' );
}

done_testing;
