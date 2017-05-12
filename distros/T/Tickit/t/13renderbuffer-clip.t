#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Tickit::Test;

use Tickit::RenderBuffer;

use Tickit::Pen;
use Tickit::Rect;

my $term = mk_term;

my $rb = Tickit::RenderBuffer->new(
   lines => 10,
   cols  => 20,
);

# Clipping to edge
{
   my $pen = Tickit::Pen->new;

   $rb->text_at( -1, 5, "TTTTTTTTTT", $pen );
   $rb->text_at( 11, 5, "BBBBBBBBBB", $pen );
   $rb->text_at( 4, -3, "[LLLLLLLL]", $pen );
   $rb->text_at( 5, 15, "[RRRRRRRR]", $pen );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(4,0), SETPEN(), PRINT("LLLLLL]"),
                 GOTO(5,15), SETPEN(), PRINT("[RRRR") ],
              'RenderBuffer text rendering with clipping' );

   $rb->erase_at( -1, 5, 10, Tickit::Pen->new( fg => 1 ) );
   $rb->erase_at( 11, 5, 10, Tickit::Pen->new( fg => 2 ) );
   $rb->erase_at( 4, -3, 10, Tickit::Pen->new( fg => 3 ) );
   $rb->erase_at( 5, 15, 10, Tickit::Pen->new( fg => 4 ) );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(4,0), SETPEN(fg=>3), ERASECH(7),
                 GOTO(5,15), SETPEN(fg=>4), ERASECH(5) ],
              'RenderBuffer text rendering with clipping' );

   $rb->goto( 2, 18 );
   $rb->text( $_, $pen ) for qw( A B C D E );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(2,18), SETPEN(), PRINT("A"), SETPEN(), PRINT("B") ],
              'RenderBuffer text at VC with clipping' );
}

# Clipping to rect
{
   my $pen = Tickit::Pen->new;

   $rb->clip( Tickit::Rect->new(
         top => 2,
         left => 2,
         bottom => 8,
         right => 18
   ) );

   $rb->text_at( 1, 5, "TTTTTTTTTT", $pen );
   $rb->text_at( 9, 5, "BBBBBBBBBB", $pen );
   $rb->text_at( 4, -3, "[LLLLLLLL]", $pen );
   $rb->text_at( 5, 15, "[RRRRRRRR]", $pen );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(4,2), SETPEN(), PRINT("LLLL]"),
                 GOTO(5,15), SETPEN(), PRINT("[RR") ],
              'RenderBuffer text rendering with clipping' );

   $rb->clip( Tickit::Rect->new(
         top => 2,
         left => 2,
         bottom => 8,
         right => 18
   ) );

   $rb->erase_at( 1, 5, 10, Tickit::Pen->new( fg => 1 ) );
   $rb->erase_at( 9, 5, 10, Tickit::Pen->new( fg => 2 ) );
   $rb->erase_at( 4, -3, 10, Tickit::Pen->new( fg => 3 ) );
   $rb->erase_at( 5, 15, 10, Tickit::Pen->new( fg => 4 ) );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(4,2), SETPEN(fg=>3), ERASECH(5),
                 GOTO(5,15), SETPEN(fg=>4), ERASECH(3) ],
              'RenderBuffer text rendering with clipping' );
}

# clipping with translation
{
   $rb->translate( 3, 5 );

   $rb->clip( Tickit::Rect->new(
         top   => 2,
         left  => 2,
         lines => 3,
         cols  => 5
   ) );

   $rb->text_at( $_, 0, "$_"x10, Tickit::Pen->new ) for 0 .. 8;

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(5,7), SETPEN(), PRINT("22222"),
                 GOTO(6,7), SETPEN(), PRINT("33333"),
                 GOTO(7,7), SETPEN(), PRINT("44444") ],
              'RenderBuffer clipping rectangle translated' );
}

done_testing;
