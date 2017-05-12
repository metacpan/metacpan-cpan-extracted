#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

my $rootwin = mk_window;
my $win = $rootwin->make_sub( 0, 0, 5, 40 );

my $scroller = Tickit::Widget::Scroller->new(
   gravity => "top",
);

$scroller->push( Tickit::Widget::Scroller::Item::Text->new( "A line of content at line $_" ) ) for 1 .. 10;

$scroller->set_window( $win );

flush_tickit;

is_display( [ "A line of content at line 1",
              "A line of content at line 2",
              "A line of content at line 3",
              "A line of content at line 4",
              "A line of content at line 5", ],
            'Display initially' );

$rootwin->clear;
$win->resize( 7, 40 );

flush_tickit;

is_display( [ "A line of content at line 1",
              "A line of content at line 2",
              "A line of content at line 3",
              "A line of content at line 4",
              "A line of content at line 5",
              "A line of content at line 6",
              "A line of content at line 7", ],
            'Display after resize more lines' );

$rootwin->clear;
$win->resize( 5, 40 );

flush_tickit;

is_display( [ "A line of content at line 1",
              "A line of content at line 2",
              "A line of content at line 3",
              "A line of content at line 4",
              "A line of content at line 5", ],
            'Display after resize fewer lines' );

$rootwin->clear;
$win->resize( 5, 20 );

flush_tickit;

is_display( [ "A line of content at",
              "line 1",
              "A line of content at",
              "line 2",
              "A line of content at", ],
            'Display after resize fewer columns' );

$rootwin->clear;
$win->resize( 15, 40 );

flush_tickit;

is_display( [ "A line of content at line 1",
              "A line of content at line 2",
              "A line of content at line 3",
              "A line of content at line 4",
              "A line of content at line 5",
              "A line of content at line 6",
              "A line of content at line 7",
              "A line of content at line 8",
              "A line of content at line 9",
              "A line of content at line 10" ],
            'Display after resize too big' );

$rootwin->clear;
$win->resize( 5, 40 );

flush_tickit;

is_display( [ "A line of content at line 1",
              "A line of content at line 2",
              "A line of content at line 3",
              "A line of content at line 4",
              "A line of content at line 5" ],
            'Display after shrink from resize too big' );

done_testing;
