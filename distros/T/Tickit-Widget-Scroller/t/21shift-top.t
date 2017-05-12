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

$scroller->push(
   Tickit::Widget::Scroller::Item::Text->new( "Existing line $_" ),
) for 1 .. 20;

$scroller->set_window( $win );

flush_tickit;

is_termlog( [ ( map { GOTO($_-1,0),
                      SETPEN,
                      PRINT("Existing line $_"),
                      SETBG(undef),
                      ERASECH(5) } 1 .. 6 ),
              GOTO(7,0) ],
            'Termlog initially' );

is_display( [ [TEXT("Existing line 1")],
              [TEXT("Existing line 2")],
              [TEXT("Existing line 3")],
              [TEXT("Existing line 4")],
              [TEXT("Existing line 5")],
              [TEXT("Existing line 6")] ],
            'Display initially' );

is_cursorpos( 7, 0, 'Cursor position intially' );

my ( $item ) = $scroller->shift;

isa_ok( $item, "Tickit::Widget::Scroller::Item::Text" );

flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,6,20, 1,0),
              GOTO(5,0),
              SETPEN,
              PRINT("Existing line 7"),
              SETBG(undef),
              ERASECH(5),
              GOTO(7,0) ],
            'Termlog after shift' );

is_display( [ [TEXT("Existing line 2")],
              [TEXT("Existing line 3")],
              [TEXT("Existing line 4")],
              [TEXT("Existing line 5")],
              [TEXT("Existing line 6")],
              [TEXT("Existing line 7")] ],
            'Display after shift' );

is_cursorpos( 7, 0, 'Cursor position after shift' );

$scroller->shift( 3 );

flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,6,20, 3,0),
              GOTO(3,0),
              SETPEN,
              PRINT("Existing line 8"),
              SETBG(undef),
              ERASECH(5),
              GOTO(4,0),
              SETPEN,
              PRINT("Existing line 9"),
              SETBG(undef),
              ERASECH(5),
              GOTO(5,0),
              SETPEN,
              PRINT("Existing line 10"),
              SETBG(undef),
              ERASECH(4),
              GOTO(7,0) ],
            'Termlog after shift 3' );

is_display( [ [TEXT("Existing line 5")],
              [TEXT("Existing line 6")],
              [TEXT("Existing line 7")],
              [TEXT("Existing line 8")],
              [TEXT("Existing line 9")],
              [TEXT("Existing line 10")] ],
            'Display after shift 3' );

is_cursorpos( 7, 0, 'Cursor position after shift 3' );

$scroller->scroll_to_bottom;
flush_tickit;
drain_termlog;

is_display( [ [TEXT("Existing line 15")],
              [TEXT("Existing line 16")],
              [TEXT("Existing line 17")],
              [TEXT("Existing line 18")],
              [TEXT("Existing line 19")],
              [TEXT("Existing line 20")] ],
            'Display after scroll_to_bottom' );

$scroller->shift;

flush_tickit;

is_termlog( [],
            'Termlog empty after shift at bottom' );

is_display( [ [TEXT("Existing line 15")],
              [TEXT("Existing line 16")],
              [TEXT("Existing line 17")],
              [TEXT("Existing line 18")],
              [TEXT("Existing line 19")],
              [TEXT("Existing line 20")] ],
            'Display unchanged after shift at bottom' );

$scroller->scroll_to_top;
flush_tickit;
drain_termlog;

is_display( [ [TEXT("Existing line 6")],
              [TEXT("Existing line 7")],
              [TEXT("Existing line 8")],
              [TEXT("Existing line 9")],
              [TEXT("Existing line 10")],
              [TEXT("Existing line 11")] ],
            'Display after scroll_to_top' );

$scroller->shift( 6 );

flush_tickit;

is_termlog( [ ( map { GOTO($_-12,0),
                      SETPEN,
                      PRINT("Existing line $_"),
                      SETBG(undef),
                      ERASECH(4) } 12 .. 17 ),
              GOTO(7,0) ],
            'Termlog after shift 6 at top' );

is_display( [ [TEXT("Existing line 12")],
              [TEXT("Existing line 13")],
              [TEXT("Existing line 14")],
              [TEXT("Existing line 15")],
              [TEXT("Existing line 16")],
              [TEXT("Existing line 17")] ],
            'Display after shift 6 at top' );

done_testing;
