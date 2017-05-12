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

$scroller->unshift(
   Tickit::Widget::Scroller::Item::Text->new( "Existing line $_" ),
) for 1 .. 20;

flush_tickit;

is_termlog( [ ( map { SETBG(undef),
                      SCROLLRECT(0,0,6,20, -1,0) } 1 .. 5, ),
              ( map { GOTO(6-$_,0),
                      SETPEN,
                      PRINT("Existing line $_"),
                      SETBG(undef),
                      ERASECH(5) } reverse 1 .. 6 ),
              GOTO(7,0) ],
            'Termlog initially' );

is_display( [ [TEXT("Existing line 6")],
              [TEXT("Existing line 5")],
              [TEXT("Existing line 4")],
              [TEXT("Existing line 3")],
              [TEXT("Existing line 2")],
              [TEXT("Existing line 1")] ],
            'Display initially' );

is_cursorpos( 7, 0, 'Cursor position intially' );

my ( $item ) = $scroller->pop;

isa_ok( $item, "Tickit::Widget::Scroller::Item::Text" );

flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,6,20, -1,0),
              GOTO(0,0),
              SETPEN,
              PRINT("Existing line 7"),
              SETBG(undef),
              ERASECH(5),
              GOTO(7,0) ],
           'Termlog after pop' );

is_display( [ [TEXT("Existing line 7")],
              [TEXT("Existing line 6")],
              [TEXT("Existing line 5")],
              [TEXT("Existing line 4")],
              [TEXT("Existing line 3")],
              [TEXT("Existing line 2")] ],
            'Display after pop' );

is_cursorpos( 7, 0, 'Cursor position after pop' );

$scroller->pop( 3 );

flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,6,20, -3,0),
              GOTO(0,0),
              SETPEN,
              PRINT("Existing line 10"),
              SETBG(undef),
              ERASECH(4),
              GOTO(1,0),
              SETPEN,
              PRINT("Existing line 9"),
              SETBG(undef),
              ERASECH(5),
              GOTO(2,0),
              SETPEN,
              PRINT("Existing line 8"),
              SETBG(undef),
              ERASECH(5),
              GOTO(7,0) ],
           'Termlog after pop 3' );

is_display( [ [TEXT("Existing line 10")],
              [TEXT("Existing line 9")],
              [TEXT("Existing line 8")],
              [TEXT("Existing line 7")],
              [TEXT("Existing line 6")],
              [TEXT("Existing line 5")] ],
            'Display after pop 3' );

is_cursorpos( 7, 0, 'Cursor position after pop 3' );

$scroller->scroll_to_top;
flush_tickit;
drain_termlog;

is_display( [ [TEXT("Existing line 20")],
              [TEXT("Existing line 19")],
              [TEXT("Existing line 18")],
              [TEXT("Existing line 17")],
              [TEXT("Existing line 16")],
              [TEXT("Existing line 15")] ],
            'Display after scroll_to_top' );

$scroller->pop;

flush_tickit;

is_termlog( [],
            'Termlog empty after pop at top' );

is_display( [ [TEXT("Existing line 20")],
              [TEXT("Existing line 19")],
              [TEXT("Existing line 18")],
              [TEXT("Existing line 17")],
              [TEXT("Existing line 16")],
              [TEXT("Existing line 15")] ],
           'Display unchanged after pop at top' );

$scroller->scroll_to_bottom;
flush_tickit;
drain_termlog;

is_display( [ [TEXT("Existing line 11")],
              [TEXT("Existing line 10")],
              [TEXT("Existing line 9")],
              [TEXT("Existing line 8")],
              [TEXT("Existing line 7")],
              [TEXT("Existing line 6")] ],
           'Display after scroll_to_bottom' );

$scroller->pop( 6 );

flush_tickit;

is_termlog( [ ( map { GOTO(17-$_,0),
                      SETPEN,
                      PRINT("Existing line $_"),
                      SETBG(undef),
                      ERASECH(4) } reverse 12 .. 17 ),
               GOTO(7,0) ],
            'Termlog after pop 6 at bottom' );

is_display( [ [TEXT("Existing line 17")],
              [TEXT("Existing line 16")],
              [TEXT("Existing line 15")],
              [TEXT("Existing line 14")],
              [TEXT("Existing line 13")],
              [TEXT("Existing line 12")] ],
           'Display after pop 6 at bottom' );

done_testing;
