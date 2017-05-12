#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test 0.12;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

# Tests are simpler if the terminal is much smaller
# TODO: mk_window once Tickit::Test can take a size there too
my ( $term, $win ) = mk_term_and_window lines => 5, cols => 15;

my $scrolled_delta = 0;
my $scroller = Tickit::Widget::Scroller->new(
   on_scrolled => sub { $scrolled_delta += $_[1] },
);

$scroller->push(
   map { Tickit::Widget::Scroller::Item::Text->new( "Item of text $_ which is long" ) } 1 .. 9
);

$scroller->set_window( $win );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN, 
              PRINT("Item of text 1 "),
              GOTO(1,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(2,0),
              SETPEN, 
              PRINT("Item of text 2 "),
              GOTO(3,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 3 ") ],
            'Termlog initially' );

is_display( [ [TEXT("Item of text 1 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 2 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 3 ")] ],
            'Display initially' );

is( $scroller->item2line( 0,  0 ), 0, 'item2line 0, 0 initially' );
is( $scroller->item2line( 0, -1 ), 1, 'item2line 0, -1 initially' );
is( $scroller->item2line( 1,  0 ), 2, 'item2line 1, 0 initially' );
is( $scroller->item2line( 1, -1 ), 3, 'item2line 1, -1 initially' );
is( $scroller->item2line( 2,  0 ), 4, 'item2line 2, 0 initially' );
is( $scroller->item2line( 2, -1 ), undef, 'item2line 2, -1 initially offscreen' );

is_deeply( [ $scroller->item2line( 2, -1 )    ], [ undef, "below" ], 'list item2line 2, -1 initially below screen' );
is_deeply( [ $scroller->item2line( 2, -1, 1 ) ], [ 5,     "below" ], 'list item2line 2, -1 initially below screen with count_offscreen' );

is( $scroller->lines_above, 0, 'lines_above initially' );
is( $scroller->lines_below, 13, 'lines_below initially' );

$scroller->scroll( +10 );

is( $scrolled_delta, 10, '$scrolled_delta after ->scroll' );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN, 
              PRINT("Item of text 6 "),
              GOTO(1,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(2,0),
              SETPEN, 
              PRINT("Item of text 7 "),
              GOTO(3,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 8 ") ],
            'Termlog after scroll +10' );

is_display( [ [TEXT("Item of text 6 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 7 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 8 ")] ],
            'Display after scroll +10' );

is( $scroller->item2line( 0,  0 ), undef, 'item2line 0, 0 offscreen after scroll +10' );
is( $scroller->item2line( 0, -1 ), undef, 'item2line 0, -1 offscreen after scroll +10' );
is( $scroller->item2line( 5,  0 ), 0, 'item2line 5, 0 after scroll +10' );
is( $scroller->item2line( 5, -1 ), 1, 'item2line 5, -1 after scroll +10' );
is( $scroller->item2line( 8,  0 ), undef, 'item2line 8, 0 offscreen after scroll +10' );

is_deeply( [ $scroller->item2line( 0, 0 )    ], [ undef, "above" ], 'list item2line 0, 0 above screen after scroll +10' );
is_deeply( [ $scroller->item2line( 0, 0, 1 ) ], [ -10,   "above" ], 'list item2line 0, 0 above screen after scroll +10 with count_offscreen' );
is_deeply( [ $scroller->item2line( 8, 0 )    ], [ undef, "below" ], 'list item2line 8, 0 below screen after scroll +10' );
is_deeply( [ $scroller->item2line( 8, 0, 1 ) ], [ 6,     "below" ], 'list item2line 8, 0 below screen after scroll +10 with count_offscreen' );

is( $scroller->lines_above, 10, 'lines_above after scroll +10' );
is( $scroller->lines_below,  3, 'lines_below after scroll +10' );

$scroller->scroll( -1 );

is( $scrolled_delta, 9, '$scrolled_delta after ->scroll -1' );

flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,5,15, -1,0),
              GOTO(0,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2) ],
            'Termlog after scroll -1' );

is_display( [ [TEXT("which is long")],
              [TEXT("Item of text 6 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 7 ")],
              [TEXT("which is long")] ],
            'Display after scroll -1' );

is( $scroller->lines_above,  9, 'lines_above after scroll -1' );
is( $scroller->lines_below,  4, 'lines_below after scroll -1' );

$scroller->scroll( +1 );

is( $scrolled_delta, 10, '$scrolled_delta after ->scroll +1' );

flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,5,15, +1,0),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 8 ") ],
            'Termlog after scroll +1' );

is_display( [ [TEXT("Item of text 6 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 7 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 8 ")] ],
            'Display after scroll +1' );

$scroller->scroll( -10 );

is( $scrolled_delta, 0, '$scrolled_delta after ->scroll -10' );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN, 
              PRINT("Item of text 1 "),
              GOTO(1,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(2,0),
              SETPEN, 
              PRINT("Item of text 2 "),
              GOTO(3,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 3 ") ],
            'Termlog after scroll -10' );

is_display( [ [TEXT("Item of text 1 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 2 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 3 ")] ],
            'Display after scroll -10' );

$scroller->scroll_to_bottom;

is( $scrolled_delta, 13, '$scrolled_delta after ->scroll_to_bottom' );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN, 
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(1,0),
              SETPEN, 
              PRINT("Item of text 8 "),
              GOTO(2,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(3,0),
              SETPEN,
              PRINT("Item of text 9 "),
              GOTO(4,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2) ],
            'Termlog after scroll_to_bottom' );

is_display( [ [TEXT("which is long")],
              [TEXT("Item of text 8 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 9 ")],
              [TEXT("which is long")] ],
            'Display after scroll_to_bottom' );

$scroller->scroll_to_top;

is( $scrolled_delta, 0, '$scrolled_delta after ->scroll_to_top' );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN, 
              PRINT("Item of text 1 "),
              GOTO(1,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(2,0),
              SETPEN, 
              PRINT("Item of text 2 "),
              GOTO(3,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 3 ") ],
            'Termlog after scroll_to_top' );

is_display( [ [TEXT("Item of text 1 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 2 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 3 ")] ],
            'Display after scroll_to_top' );

$scroller->scroll_to( 2, 4, 0 ); # About halfway

is( $scrolled_delta, 6, '$scrolled_delta after ->scroll_to halfway' );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN, 
              PRINT("Item of text 4 "),
              GOTO(1,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(2,0),
              SETPEN, 
              PRINT("Item of text 5 "),
              GOTO(3,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2),
              GOTO(4,0),
              SETPEN,
              PRINT("Item of text 6 ") ],
            'Termlog after scroll_to middle' );

is_display( [ [TEXT("Item of text 4 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 5 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 6 ")] ],
            'Display after scroll_to middle' );

$scroller->scroll( +5 );
flush_tickit;
drain_termlog;

{
   my $pre_scroll_delta = $scrolled_delta;

   $scroller->scroll( +5 ); # over the end

   is( $scrolled_delta - $pre_scroll_delta, 2, 'on_scroll given actual delta, not requested' );
   is( $scrolled_delta, 13, '$scrolled_delta after ->scroll +5 over the end' );
}

flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,5,15, +2,0),
              GOTO(3,0),
              SETPEN, 
              PRINT("Item of text 9 "),
              GOTO(4,0),
              SETPEN,
              PRINT("which is long"),
              SETBG(undef),
              ERASECH(2) ],
            'Termlog down past the end' );

is_display( [ [TEXT("which is long")],
              [TEXT("Item of text 8 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 9 ")],
              [TEXT("which is long")] ],
            'Display after scroll down past the end' );

$scroller->scroll( -2 );
$scroller->scroll( -2 );
flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,5,15, -2,0),
              SETBG(undef),
              SCROLLRECT(0,0,5,15, -2,0),
              GOTO(0,0), SETPEN, PRINT("which is long"), SETBG(undef), ERASECH(2),
              GOTO(1,0), SETPEN, PRINT("Item of text 6 "),
              GOTO(2,0), SETPEN, PRINT("which is long"), SETBG(undef), ERASECH(2),
              GOTO(3,0), SETPEN, PRINT("Item of text 7 "), ],
            'Termlog after ->scroll(-2) x 2' );

is_display( [ [TEXT("which is long")],
              [TEXT("Item of text 6 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 7 ")],
              [TEXT("which is long")] ],
            'Display after ->scroll(-2) x 2' );

$scroller->scroll( +2 );
$scroller->scroll( +2 );
flush_tickit;

is_termlog( [ SETBG(undef),
              SCROLLRECT(0,0,5,15, +2,0),
              SETBG(undef),
              SCROLLRECT(0,0,5,15, +2,0),
              GOTO(1,0), SETPEN, PRINT("Item of text 8 "),
              GOTO(2,0), SETPEN, PRINT("which is long"), SETBG(undef), ERASECH(2),
              GOTO(3,0), SETPEN, PRINT("Item of text 9 "),
              GOTO(4,0), SETPEN, PRINT("which is long"), SETBG(undef), ERASECH(2), ],
            'Termlog after ->scroll(+2) x 2' );

is_display( [ [TEXT("which is long")],
              [TEXT("Item of text 8 ")],
              [TEXT("which is long")],
              [TEXT("Item of text 9 ")],
              [TEXT("which is long")] ],
            'Display after ->scroll(+2) x 2' );

is( $scrolled_delta, 13, '$scrolled_delta before EOF' );

done_testing;
