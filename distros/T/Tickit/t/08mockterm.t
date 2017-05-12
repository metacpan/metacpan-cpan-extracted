#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Tickit::Test;

use Tickit::Pen;

my $term = mk_term lines => 3, cols => 10;

is_termlog( [],
            'Termlog initially' );
is_display( [ "", "", "" ],
            'Display initially' );

$term->goto( 1, 5 );

is_termlog( [ GOTO(1,5) ],
            'Termlog after ->goto' );
is_cursorpos( 1, 5, 'Cursor position after ->goto' );

$term->print( "foo" );

is_termlog( [ PRINT("foo") ],
            'Termlog after ->print' );
is_display( [ "", "     foo", "" ],
            'Display after ->print' );
is_cursorpos( 1, 8, 'Cursor position after ->print' );

$term->clear;

is_termlog( [ CLEAR ],
            'Termlog after ->clear' );
is_display( [ "", "", "" ],
            'Display after ->clear' );

$term->setpen( Tickit::Pen->new( fg => 3 ) );

is_termlog( [ SETPEN(fg=>3) ],
            'Termlog after ->setpen' );

$term->chpen( Tickit::Pen->new( bg => 6 ) );

is_termlog( [ SETPEN(fg=>3,bg=>6) ],
            'Termlog after ->chpen' );

# Now some test content for scrolling
for my $l ( 0 .. 2 ) { $term->goto( $l, 0 ); $term->print( $l x 10 ) }
drain_termlog;

is_display( [ "0000000000", "1111111111", "2222222222" ],
            'Display after scroll fill' );

ok( $term->scrollrect( 0,0,3,10, +1,0 ), '$term->scrollrect down OK' );
is_termlog( [ SCROLLRECT(0,0,3,10, +1,0) ],
            'Termlog after scroll 1 down' );
is_display( [ "1111111111", "2222222222", "" ],
            'Display after scroll 1 down' );

ok( $term->scrollrect( 0,0,3,10, -1,0 ), '$term->scrollrect up OK' );
is_termlog( [ SCROLLRECT(0,0,3,10, -1,0) ],
            'Termlog after scroll 1 up' );
is_display( [ "", "1111111111", "2222222222" ],
            'Display after scroll 1 up' );

for my $l ( 0 .. 2 ) { $term->goto( $l, 0 ); $term->print( $l x 10 ) }
drain_termlog;

$term->scrollrect( 0,0,2,10, +1,0 );
is_termlog( [ SCROLLRECT(0,0,2,10, +1,0) ],
            'Termlog after scroll partial 1 down' );
is_display( [ "1111111111", "", "2222222222" ],
            'Display after scroll partial 1 down' );

$term->scrollrect( 0,0,2,10, -1,0 );
is_termlog( [ SCROLLRECT(0,0,2,10, -1,0) ],
            'Termlog after scroll partial 1 up' );
is_display( [ "", "1111111111", "2222222222" ],
            'Display after scroll partial 1 up' );

$term->scrollrect( 1,5,1,5, 0,2 );
is_termlog( [ SCROLLRECT(1,5,1,5, ,0,+2) ],
            'Termlog after scroll right' );
is_display( [ "", "11111111  ", "2222222222" ],
            'Display after scroll right' );

$term->scrollrect( 2,5,1,5, 0,-3 );
is_termlog( [ SCROLLRECT(2,5,1,5, ,0,-3) ],
            'Termlog after scroll left' );
is_display( [ "", "11111111  ", "22222   22" ],
            'Display after scroll left' );

# Now some test content for mangling
for my $l ( 0 .. 2 ) { $term->goto( $l, 0 ); $term->print( "ABCDEFGHIJ" ) }
drain_termlog;

$term->goto( 0, 3 );
$term->erasech( 5, undef );
is_display( [ "ABC     IJ", "ABCDEFGHIJ", "ABCDEFGHIJ" ],
            'Display after ->erasech' );

done_testing;
