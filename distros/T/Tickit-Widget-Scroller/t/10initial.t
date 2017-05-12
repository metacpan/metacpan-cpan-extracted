#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

my $win = mk_window;

my $scroller = Tickit::Widget::Scroller->new;

ok( defined $scroller, 'defined $scroller' );

$scroller->push(
   map { Tickit::Widget::Scroller::Item::Text->new( $_ ) }
      "The first line",
      "Another line in the middle",
      "The third line",
);

$scroller->set_window( $win );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("The first line"),
              SETBG(undef),
              ERASECH(66),
              GOTO(1,0),
              SETPEN,
              PRINT("Another line in the middle"),
              SETBG(undef),
              ERASECH(54),
              GOTO(2,0),
              SETPEN,
              PRINT("The third line"),
              SETBG(undef),
              ERASECH(66),
              map { GOTO($_,0), SETBG(undef), ERASECH(80) } 3 .. 24 ],
            'Termlog initially' );

is_display( [ "The first line",
              "Another line in the middle",
              "The third line" ],
            'Display initially' );

is( scalar $scroller->line2item( 0 ),     0, 'scalar line2item 0' );
is_deeply( [ $scroller->line2item( 0 ) ], [ 0, 0 ], 'line2item 0' );
is_deeply( [ $scroller->line2item( 1 ) ], [ 1, 0 ], 'line2item 1' );
is_deeply( [ $scroller->line2item( 2 ) ], [ 2, 0 ], 'line2item 2' );
is_deeply( [ $scroller->line2item( 3 ) ], [ ],      'line2item 3' );

is_deeply( [ $scroller->line2item( -1 ) ], [ ],      'line2item -1' );
is_deeply( [ $scroller->line2item( -23 ) ], [ 2, 0 ], 'line2item -23' );

is( $scroller->item2line( 0 ),     0, 'item2line 0' );
is( $scroller->item2line( 0, -1 ), 0, 'item2line 0, -1' );
is( $scroller->item2line( 1 ),     1, 'item2line 1' );
is( $scroller->item2line( 2 ),     2, 'item2line 2' );

is( $scroller->item2line( -1 ), 2, 'item2line -1' );

resize_term( 25, 20 );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("The first line"),
              SETBG(undef),
              ERASECH(6),
              GOTO(1,0),
              SETPEN,
              PRINT("Another line in the "),
              GOTO(2,0),
              SETPEN,
              PRINT("middle"),
              SETBG(undef),
              ERASECH(14),
              GOTO(3,0),
              SETPEN,
              PRINT("The third line"),
              SETBG(undef),
              ERASECH(6),
              map { GOTO($_,0), SETBG(undef), ERASECH(20) } 4 .. 24 ],
            'Termlog after narrowing' );

is_display( [ "The first line",
              "Another line in the ",
              "middle",
              "The third line" ],
            'Display after narrowing' );

is_deeply( [ $scroller->line2item( 0 ) ], [ 0, 0 ], 'line2item 0' );
is_deeply( [ $scroller->line2item( 1 ) ], [ 1, 0 ], 'line2item 1' );
is_deeply( [ $scroller->line2item( 2 ) ], [ 1, 1 ], 'line2item 2' );
is_deeply( [ $scroller->line2item( 3 ) ], [ 2, 0 ], 'line2item 3' );
is_deeply( [ $scroller->line2item( 4 ) ], [ ],      'line2item 4' );

is_deeply( [ $scroller->line2item( -1 ) ], [ ],      'line2item -1' );
is_deeply( [ $scroller->line2item( -22 ) ], [ 2, 0 ], 'line2item -22' );

is( $scroller->item2line( 0 ),     0, 'item2line 0' );
is( $scroller->item2line( 0, -1 ), 0, 'item2line 0, -1' );
is( $scroller->item2line( 1 ),     1, 'item2line 1' );
is( $scroller->item2line( 1, -1 ), 2, 'item2line 1, -1' );
is( $scroller->item2line( 2 ),     3, 'item2line 2' );

is( $scroller->item2line( -1 ), 3, 'item2line -1' );

done_testing;
