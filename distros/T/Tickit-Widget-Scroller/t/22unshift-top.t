#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test 0.12;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

# TODO: mk_window once Tickit::Test can take a size there too
my ( $term, $rootwin ) = mk_term_and_window cols => 20, lines => 8;
my $win = $rootwin->make_sub( 0, 0, 6, 20 );

$rootwin->focus( 7, 0 );

my $scroller = Tickit::Widget::Scroller->new(
   gravity => "top",
);

$scroller->set_window( $win );

flush_tickit;

is_termlog( [ ( map { GOTO($_,0), SETBG(undef), ERASECH(20) } 0 .. 5 ),
              GOTO(7,0) ],
            'Termlog initially' );

is_display( [ ],
            'Display initially' );

is_cursorpos( 7, 0, 'Cursor position intially' );

$scroller->unshift(
   Tickit::Widget::Scroller::Item::Text->new( "A line of text" ),
);

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("A line of text"),
              SETBG(undef),
              ERASECH(6),
              GOTO(7,0) ],
            'Termlog after unshift' );

is_display( [ [TEXT("A line of text")] ],
            'Display after unshift' );

is_cursorpos( 7, 0, 'Cursor position after unshift' );

$scroller->unshift( reverse
   map { Tickit::Widget::Scroller::Item::Text->new( "Another line $_" ) } 1 .. 4,
);

flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,6,20, -4,0),
              GOTO(0,0),
              SETPEN,
              PRINT("Another line 4"),
              SETBG(undef),
              ERASECH(6),
              GOTO(1,0),
              SETPEN,
              PRINT("Another line 3"),
              SETBG(undef),
              ERASECH(6),
              GOTO(2,0),
              SETPEN,
              PRINT("Another line 2"),
              SETBG(undef),
              ERASECH(6),
              GOTO(3,0),
              SETPEN,
              PRINT("Another line 1"),
              SETBG(undef),
              ERASECH(6),
              GOTO(7,0) ],
            'Termlog after unshift 4' );

is_display( [ [TEXT("Another line 4")],
              [TEXT("Another line 3")],
              [TEXT("Another line 2")],
              [TEXT("Another line 1")],
              [TEXT("A line of text")] ],
            'Display after unshift 4' );

is_cursorpos( 7, 0, 'Cursor position after unshift 4' );

$scroller->unshift( Tickit::Widget::Scroller::Item::Text->new( "An item of text that wraps" ) );

flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,6,20, -2,0),
              GOTO(0,0),
              SETPEN,
              PRINT("An item of text that"),
              GOTO(1,0),
              SETPEN,
              PRINT("wraps"),
              SETBG(undef),
              ERASECH(15),
              GOTO(7,0) ],
            'Termlog after unshift wrapping' );

is_display( [ [TEXT("An item of text that")],
              [TEXT("wraps")],
              [TEXT("Another line 4")],
              [TEXT("Another line 3")],
              [TEXT("Another line 2")],
              [TEXT("Another line 1")] ],
            'Display after unshift wrapping' );

is_cursorpos( 7, 0, 'Cursor position after unshift wrapping' );

$scroller->unshift( reverse
   map { Tickit::Widget::Scroller::Item::Text->new( "Another line $_" ) } 5 .. 10,
);

flush_tickit;
drain_termlog;

is_display( [ [TEXT("Another line 10")],
              [TEXT("Another line 9")],
              [TEXT("Another line 8")],
              [TEXT("Another line 7")],
              [TEXT("Another line 6")],
              [TEXT("Another line 5")], ],
            'Display after unshift 6' );

is_cursorpos( 7, 0, 'Cursor position after unshift 6' );

$scroller->set_window( undef );

$scroller->unshift( Tickit::Widget::Scroller::Item::Text->new( "A line while offscreen" ) );

$scroller->set_window( $win );

flush_tickit;
drain_termlog;

is_display( [ [TEXT("Another line 10")],
              [TEXT("Another line 9")],
              [TEXT("Another line 8")],
              [TEXT("Another line 7")],
              [TEXT("Another line 6")],
              [TEXT("Another line 5")], ],
            'Display after unshift while offscreen' );

is_cursorpos( 7, 0, 'Cursor position after unshift while offscreen' );

$scroller->scroll_to_bottom;

flush_tickit;
drain_termlog;

is_display( [ [TEXT("wraps")],
              [TEXT("Another line 4")],
              [TEXT("Another line 3")],
              [TEXT("Another line 2")],
              [TEXT("Another line 1")],
              [TEXT("A line of text")] ],
            'Display after scroll_to_bottom' );

is_cursorpos( 7, 0, 'Cursor position after scroll_to_bottom' );

$scroller->unshift(
   Tickit::Widget::Scroller::Item::Text->new( "Unseen line" ),
);

is_termlog( [],
            'Termlog empty after unshift at tail' );

is_display( [ [TEXT("wraps")],
              [TEXT("Another line 4")],
              [TEXT("Another line 3")],
              [TEXT("Another line 2")],
              [TEXT("Another line 1")],
              [TEXT("A line of text")] ],
            'Display after unshift at tail' );

is_cursorpos( 7, 0, 'Cursor position after unshift at tail' );

done_testing;
