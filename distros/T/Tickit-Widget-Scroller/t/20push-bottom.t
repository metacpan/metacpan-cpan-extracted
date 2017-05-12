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
   gravity => "bottom",
);

$scroller->set_window( $win );

flush_tickit;

is_termlog( [ ( map { GOTO($_,0), SETBG(undef), ERASECH(20) } 0 .. 5 ),
              GOTO(7,0) ],
            'Termlog initially' );

is_display( [ ],
            'Display initially' );

is_cursorpos( 7, 0, 'Cursor position intially' );

$scroller->push(
   Tickit::Widget::Scroller::Item::Text->new( "A line of text" ),
);

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("A line of text"),
              SETBG(undef),
              ERASECH(6),
              GOTO(7,0) ],
            'Termlog after push' );

is_display( [ [TEXT("A line of text")] ],
            'Display after push' );

is_cursorpos( 7, 0, 'Cursor position after push' );

$scroller->push(
   map { Tickit::Widget::Scroller::Item::Text->new( "Another line $_" ) } 1 .. 4,
);

flush_tickit;

is_termlog( [ GOTO(1,0),
              SETPEN,
              PRINT("Another line 1"),
              SETBG(undef),
              ERASECH(6),
              GOTO(2,0),
              SETPEN,
              PRINT("Another line 2"),
              SETBG(undef),
              ERASECH(6),
              GOTO(3,0),
              SETPEN,
              PRINT("Another line 3"),
              SETBG(undef),
              ERASECH(6),
              GOTO(4,0),
              SETPEN,
              PRINT("Another line 4"),
              SETBG(undef),
              ERASECH(6),
              GOTO(7,0) ],
            'Termlog after push 4' );

is_display( [ [TEXT("A line of text")],
              [TEXT("Another line 1")],
              [TEXT("Another line 2")],
              [TEXT("Another line 3")],
              [TEXT("Another line 4")] ],
            'Display after push 4' );

is_cursorpos( 7, 0, 'Cursor position after push 4' );

$scroller->push( Tickit::Widget::Scroller::Item::Text->new( "An item of text that wraps" ) );

flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,6,20, 1,0),
              GOTO(4,0),
              SETPEN,
              PRINT("An item of text that"),
              GOTO(5,0),
              SETPEN,
              PRINT("wraps"),
              SETBG(undef),
              ERASECH(15),
              GOTO(7,0) ],
            'Termlog after push wrapping' );

is_display( [ [TEXT("Another line 1")],
              [TEXT("Another line 2")],
              [TEXT("Another line 3")],
              [TEXT("Another line 4")],
              [TEXT("An item of text that")],
              [TEXT("wraps")] ],
            'Display after push wrapping' );

is_cursorpos( 7, 0, 'Cursor position after push wrapping' );

$scroller->push(
   map { Tickit::Widget::Scroller::Item::Text->new( "Another line $_" ) } 5 .. 10,
);

flush_tickit;
drain_termlog;

is_display( [ [TEXT("Another line 5")],
              [TEXT("Another line 6")],
              [TEXT("Another line 7")],
              [TEXT("Another line 8")],
              [TEXT("Another line 9")],
              [TEXT("Another line 10")] ],
            'Display after push 6' );

is_cursorpos( 7, 0, 'Cursor position after push 6' );

$scroller->set_window( undef );

$scroller->push( Tickit::Widget::Scroller::Item::Text->new( "A line while offscreen" ) );

$scroller->set_window( $win );

flush_tickit;
drain_termlog;

is_display( [ [TEXT("Another line 7")],
              [TEXT("Another line 8")],
              [TEXT("Another line 9")],
              [TEXT("Another line 10")],
              [TEXT("A line while ")],
              [TEXT("offscreen")] ],
            'Display after push while offscreen' );

is_cursorpos( 7, 0, 'Cursor position after push while offscreen' );

$scroller->scroll_to_top;

flush_tickit;
drain_termlog;

is_display( [ [TEXT("A line of text")],
              [TEXT("Another line 1")],
              [TEXT("Another line 2")],
              [TEXT("Another line 3")],
              [TEXT("Another line 4")],
              [TEXT("An item of text that")] ],
            'Display after scroll_to_top' );

is_cursorpos( 7, 0, 'Cursor position after push scroll_to_top' );

$scroller->push(
   Tickit::Widget::Scroller::Item::Text->new( "Unseen line" ),
);

is_termlog( [],
            'Termlog empty after push at head' );

is_display( [ [TEXT("A line of text")],
              [TEXT("Another line 1")],
              [TEXT("Another line 2")],
              [TEXT("Another line 3")],
              [TEXT("Another line 4")],
              [TEXT("An item of text that")] ],
            'Display after push at head' );

is_cursorpos( 7, 0, 'Cursor position after push at head' );

done_testing;
