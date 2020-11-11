#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Entry;

my $win = mk_window;

my $entry = Tickit::Widget::Entry->new(
   text => "A"x70,
   position => 70,
);

$entry->set_window( $win );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("A"x70),
              SETBG(undef),
              ERASECH(10),
              ( map { GOTO($_,0), SETBG(undef), ERASECH(80) } 1 .. 24 ),
              GOTO(0,70) ],
            'Termlog initially' );

is_display( [ "A"x70 ],
            'Display initially' );

is_cursorpos( 0, 70, 'Position initially' );

$entry->text_insert( "B"x20, $entry->position );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN(fg => 6),
              PRINT("<.."),
              SETPEN,
              PRINT(("A"x27).("B"x20)),
              SETBG(undef),
              ERASECH(30),
              ( map { GOTO($_,0), SETBG(undef), ERASECH(80) } 1 .. 24 ),
              GOTO(0,50) ],
            'Termlog after append to scroll' );

is_display( [ "<..".("A"x27).("B"x20) ],
            'Display after append to scroll' );

is_cursorpos( 0, 50, 'Position after append to scroll' );

$entry->set_position( 0 );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT(("A"x70).("B"x7)),
              SETPEN(fg => 6),
              PRINT("..>"),
              ( map { GOTO($_,0), SETBG(undef), ERASECH(80) } 1 .. 24 ),
              GOTO(0,0) ],
            'Termlog after ->set_position 0' );

is_display( [ ("A"x70).("B"x7)."..>" ],
            'Display after ->set_position 0' );

is_cursorpos( 0, 0, 'Position after ->set_position 0' );

$entry->set_position( 90 );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN(fg => 6),
              PRINT("<.."),
              SETPEN,
              PRINT(("A"x27).("B"x20)),
              SETBG(undef),
              ERASECH(30),
              ( map { GOTO($_,0), SETBG(undef), ERASECH(80) } 1 .. 24 ),
              GOTO(0,50) ],
            'Termlog after ->set_position 90' );

is_display( [ "<..".("A"x27).("B"x20) ],
            'Display after ->set_position 90' );

is_cursorpos( 0, 50, 'Position after ->set_position 90' );

$entry->set_position( 0 );

flush_tickit;
drain_termlog;

$entry->text_delete( 0, 1 );

flush_tickit;

is_termlog( [ SETBG(undef),
              ( $Tickit::Test::MockTerm::VERSION >= 0.45 ?
                  ( SCROLLRECT(0,0,1,80, 0,1) ) :
                  ( GOTO(0,0), DELETECH(1) ) ),
              GOTO(0,76),
              SETPEN,
              PRINT("B"),
              SETPEN(fg=>6),
              PRINT("..>"),
              GOTO(0,0) ],
            'Termlog after ->text_delete 0, 1' );

is_display( [ ("A"x69).("B"x8)."..>" ],
            'Display after ->text_delete 0, 1' );

is_cursorpos( 0, 0, 'Position after ->text_delete 0, 1' );

done_testing;
