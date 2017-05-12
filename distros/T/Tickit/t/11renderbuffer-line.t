#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use Tickit::Test;

use Tickit::RenderBuffer qw( LINE_SINGLE CAP_START CAP_END CAP_BOTH );

use Tickit::Pen;

my $term = mk_term;

my $rb = Tickit::RenderBuffer->new(
   lines => 30,
   cols  => 30,
);

my $pen = Tickit::Pen->new;

# Simple lines explicit pen
{
   $rb->hline_at( 10, 10, 20, LINE_SINGLE, $pen );
   $rb->hline_at( 11, 10, 20, LINE_SINGLE, $pen, CAP_START );
   $rb->hline_at( 12, 10, 20, LINE_SINGLE, $pen, CAP_END );
   $rb->hline_at( 13, 10, 20, LINE_SINGLE, $pen, CAP_BOTH );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(10,10), SETPEN, PRINT("╶".("─"x9)."╴"),
                 GOTO(11,10), SETPEN, PRINT(("─"x10)."╴"),
                 GOTO(12,10), SETPEN, PRINT("╶".("─"x10)),
                 GOTO(13,10), SETPEN, PRINT(("─"x11)) ],
               'RenderBuffer renders hline_ats to terminal' );

   $rb->vline_at( 10, 20, 10, LINE_SINGLE, $pen );
   $rb->vline_at( 10, 20, 11, LINE_SINGLE, $pen, CAP_START );
   $rb->vline_at( 10, 20, 12, LINE_SINGLE, $pen, CAP_END );
   $rb->vline_at( 10, 20, 13, LINE_SINGLE, $pen, CAP_BOTH );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(10,10), SETPEN, PRINT("╷│╷│"),
                 ( map { GOTO($_,10), SETPEN, PRINT("││││") } 11 .. 19 ),
                 GOTO(20,10), SETPEN, PRINT("╵╵││") ],
               'RenderBuffer renders vline_ats to terminal' );
}

# Lines setpen
{
   $rb->setpen( Tickit::Pen->new( bg => 3 ) );

   $rb->hline_at( 10, 5, 15, LINE_SINGLE );
   $rb->vline_at( 5, 15, 10, LINE_SINGLE );

   my $cell = $rb->get_cell( 6, 10 );
   is( $cell->linemask->north, LINE_SINGLE, '$cell->linemask->north at 6,10' );
   is( $cell->linemask->south, LINE_SINGLE, '$cell->linemask->south at 6,10' );
   is( $cell->linemask->east,  0,           '$cell->linemask->east at 6,10' );
   is( $cell->linemask->west,  0,           '$cell->linemask->west at 6,10' );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(5,10), SETPEN(bg=>3), PRINT("╷"),
                 ( map { GOTO($_,10), SETPEN(bg=>3), PRINT("│") } 6 .. 9 ),
                 GOTO(10,5), SETPEN(bg=>3), PRINT("╶────┼────╴"),
                 ( map { GOTO($_,10), SETPEN(bg=>3), PRINT("│") } 11 .. 14 ),
                 GOTO(15,10), SETPEN(bg=>3), PRINT("╵") ],
              'RenderBuffer renders lines with stored pen' );

   # cheating
   $rb->setpen( undef );
}

# Line merging
{
   $rb->hline_at( 10, 10, 14, LINE_SINGLE, $pen );
   $rb->hline_at( 12, 10, 14, LINE_SINGLE, $pen );
   $rb->hline_at( 14, 10, 14, LINE_SINGLE, $pen );
   $rb->vline_at( 10, 14, 10, LINE_SINGLE, $pen );
   $rb->vline_at( 10, 14, 12, LINE_SINGLE, $pen );
   $rb->vline_at( 10, 14, 14, LINE_SINGLE, $pen );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(10,10), SETPEN(), PRINT("┌─┬─┐"),
                 GOTO(11,10), SETPEN(), PRINT("│"),
                    GOTO(11,12), SETPEN(), PRINT("│"),
                    GOTO(11,14), SETPEN(), PRINT("│"),
                 GOTO(12,10), SETPEN(), PRINT("├─┼─┤"),
                 GOTO(13,10), SETPEN(), PRINT("│"),
                    GOTO(13,12), SETPEN(), PRINT("│"),
                    GOTO(13,14), SETPEN(), PRINT("│"),
                 GOTO(14,10), SETPEN(), PRINT("└─┴─┘"),
              ],
              'RenderBuffer renders line merging' );
}

# Linebox
{
   $rb->linebox_at( 3, 6, 3, 6, LINE_SINGLE, $pen );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(3,3), SETPEN(), PRINT("┌──┐"),
                 GOTO(4,3), SETPEN(), PRINT("│"),
                    GOTO(4,6), SETPEN(), PRINT("│"),
                 GOTO(5,3), SETPEN(), PRINT("│"),
                    GOTO(5,6), SETPEN(), PRINT("│"),
                 GOTO(6,3), SETPEN(), PRINT("└──┘") ],
              'RenderBuffer renders linebox_at' );
}

done_testing;
