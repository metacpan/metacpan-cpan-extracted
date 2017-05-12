#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Entry;

my ( $term, $win ) = mk_term_and_window;

my $entry = Tickit::Widget::Entry->new;

ok( defined $entry, 'defined $entry' );

is( $entry->text,     "", '$entry->text initially' );
is( $entry->position, 0,  '$entry->position initially' );

$entry->set_window( $win );
flush_tickit;

is_termlog( [ GOTO(0,0),
              SETBG(undef),
              ERASECH(80),
              ( map { GOTO($_,0), SETBG(undef), ERASECH(80) } 1 .. 24 ),
              GOTO(0,0) ],
            'Termlog initially' );

is_display( [],
            'Display initially' );

is_cursorpos( 0, 0, 'Position initally' );

$entry->text_insert( "Hello", 0 );
flush_tickit;

is( $entry->text,     "Hello", '$entry->text after ->text_insert' );
is( $entry->position, 5,       '$entry->position after ->text_insert' );

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("Hello"),
              GOTO(0,5) ],
            'Termlog after ->text_insert' );

is_display( [ "Hello" ],
            'Display after ->text_insert' );

is_cursorpos( 0, 5, 'Position after ->text_insert' );

$entry->text_insert( " ", 0 );
is( $entry->text,     " Hello", '$entry->text after ->text_insert at 0' );
is( $entry->position, 6,        '$entry->position after ->text_insert at 0' );

flush_tickit;

is_termlog( [ SETBG(undef),
              ( $Tickit::Test::MockTerm::VERSION >= 0.45 ?
                  ( SCROLLRECT(0,0,1,80, 0,-1) ) :
                  ( GOTO(0,0), INSERTCH(1) ) ),
              GOTO(0,0),
              SETPEN,
              PRINT(" "),
              GOTO(0,6) ],
            'Termlog after ->text_insert at 0' );

is_display( [ " Hello" ],
            'Display after ->text_insert at 0' );

is_cursorpos( 0, 6, 'Position after ->text_insert at 0' );

is( $entry->text_delete( 5, 1 ), "o", '$entry->text_delete' );
is( $entry->text,     " Hell", '$entry->text after ->text_delete' );
is( $entry->position, 5,       '$entry->position after ->text_delete' );

flush_tickit;

is_termlog( [ SETBG(undef),
              ( $Tickit::Test::MockTerm::VERSION >= 0.45 ?
                  ( SCROLLRECT(0,5,1,75, 0,1) ) :
                  ( GOTO(0,5), DELETECH(1) ) ),
              GOTO(0,79),
              SETBG(undef),
              ERASECH(1),
              GOTO(0,5) ],
            'Termlog after ->text_delete' );

is_display( [ " Hell" ],
            'Display after ->text_delete' );

is_cursorpos( 0, 5, 'Position after ->text_delete' );

is( $entry->text_splice( 0, 2, "Y" ), " H", '$entry->text_splice shrink' );
is( $entry->text,     "Yell", '$entry->text after ->text_splice shrink' );
is( $entry->position, 4,      '$entry->position after ->text_splice shrink' );

flush_tickit;

is_termlog( [ SETBG(undef),
              ( $Tickit::Test::MockTerm::VERSION >= 0.45 ?
                  ( SCROLLRECT(0,0,1,80, 0,1) ) :
                  ( GOTO(0,0), DELETECH(1) ) ),
              GOTO(0,0),
              SETPEN,
              PRINT("Y"),
              GOTO(0,79),
              SETBG(undef),
              ERASECH(1),
              GOTO(0,4) ],
            'Termlog after ->text_splice shrink' );

is_display( [ "Yell" ],
            'Display after ->text_splice shrink' );

is_cursorpos( 0, 4, 'Position after ->text_splice shrink' );

is( $entry->text_splice( 3, 1, "p" ), "l", '$entry->text_splice preserve' );
is( $entry->text,     "Yelp", '$entry->text after ->text_splice preserve' );
is( $entry->position, 4,      '$entry->position after ->text_splice preserve' );

flush_tickit;

is_termlog( [ GOTO(0,3),
              SETPEN,
              PRINT("p"),
              GOTO(0,4) ],
            'Termlog after ->text_splice preserve' );

is_display( [ "Yelp" ],
            'Display after ->text_splice preserve' );

is_cursorpos( 0, 4, 'Position after ->text_splice preserve' );

is( $entry->text_splice( 3, 1, "low" ), "p", '$entry->text_splice grow' );
is( $entry->text,     "Yellow", '$entry->text after ->text_splice grow' );
is( $entry->position, 6,        '$entry->position after ->text_splice grow' );

flush_tickit;

is_termlog( [ SETBG(undef),
              ( $Tickit::Test::MockTerm::VERSION >= 0.45 ?
                  ( SCROLLRECT(0,3,1,77, 0,-2) ) :
                  ( GOTO(0,3), INSERTCH(2) ) ),
              GOTO(0,3),
              SETPEN,
              PRINT("low"),
              GOTO(0,6) ],
            'Termlog after ->text_splice grow' );

is_display( [ "Yellow" ],
            'Display after ->text_splice grow' );

is_cursorpos( 0, 6, 'Position after ->text_splice grow' );

$entry->set_position( 3 );

is( $entry->position, 3, '$entry->position after ->set_position' );

flush_tickit;

is_termlog( [ GOTO(0,3) ],
            'Termlog after ->set_position' );

is_display( [ "Yellow" ],
            'Display after ->set_position' );

is_cursorpos( 0, 3, 'Position after ->set_position' );

$entry->set_text( "Different text" );

is( $entry->text, "Different text", '$entry->text after ->set_text' );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("Different text"),
              SETBG(undef),
              ERASECH(66),
              ( map { GOTO($_,0), SETBG(undef), ERASECH(80) } 1 .. 24 ),
              GOTO(0,3) ],
            'Termlog after ->set_text' );

is_display( [ "Different text" ],
            'Display after ->set_text' );

is_cursorpos( 0, 3, 'Position after ->set_text' );

$entry->set_window( undef );
$term->clear;
drain_termlog;

# A window that doesn't extend to righthand edge of screen, so ICH/DCH won't
# work
{
   my $subwin = $win->make_sub( 2, 2, $win->lines - 4, $win->cols - 4 );

   $entry->set_window( $subwin );
   $entry->take_focus;

   flush_tickit;

   is_termlog( [ GOTO(2,2),
                 SETPEN,
                 PRINT("Different text"),
                 SETBG(undef),
                 ERASECH(62),
                 ( map { GOTO($_,2), SETBG(undef), ERASECH(76) } 3 .. 22 ),
                 GOTO(2,5) ],
               'Termlog in subwindow' );

   is_display( [ "", "", "  Different text" ],
               'Display in subwindow' );

   $entry->text_insert( "And ", 0 );

   flush_tickit;

   is_termlog( [ SETBG(undef),
                 GOTO(2,2),
                 SETBG(undef),
                 PRINT("And Different text"),
                 SETBG(undef),
                 ERASECH(58),
                 GOTO(2,9) ], # TODO: Maybe these can be made more efficient?
               'Termlog after ->text_insert in subwindow' );

   is_display( [ "", "", "  And Different text" ],
               'Display after ->text_insert in subwindow' );

   $entry->set_window( undef );

   $subwin->close;
}

$entry = Tickit::Widget::Entry->new(
   text     => "Some initial text",
   position => 5,
);

is( $entry->text,     "Some initial text", '$entry->text for initialised' );
is( $entry->position, 5,                   '$entry->position for initialised' );

$entry->set_window( $win );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("Some initial text"),
              SETBG(undef),
              ERASECH(63),
              ( map { GOTO($_,0), SETBG(undef), ERASECH(80) } 1 .. 24 ),
              GOTO(0,5) ],
           'Termlog written to for initialised' );

is_display( [ "Some initial text" ],
            'Display for initialised' );

is_cursorpos( 0, 5, 'Position for initalised' );

is( $entry->find_bow_forward( 9 ), 13, 'find_bow_forward( 9 )' );
is( $entry->find_eow_forward( 9 ), 12, 'find_eow_forward( 9 )' );
is( $entry->find_bow_backward( 9 ), 5, 'find_bow_backward( 9 )' );
is( $entry->find_eow_backward( 9 ), 4, 'find_eow_backward( 9 )' );

is( $entry->find_bow_forward( 15 ), undef, 'find_bow_forward( 15 )' );
is( $entry->find_eow_forward( 15 ), 17,    'find_eow_forward( 15 )' );

is( $entry->find_bow_backward( 2 ), 0,     'find_bow_backward( 2 )' );
is( $entry->find_eow_backward( 2 ), undef, 'find_eow_backward( 2 )' );

done_testing;
