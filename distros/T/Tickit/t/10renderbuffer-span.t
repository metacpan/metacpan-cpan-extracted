#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use Tickit::Test;

use Tickit::RenderBuffer;

use Tickit::Pen;

my $term = mk_term;

my $rb = Tickit::RenderBuffer->new(
   lines => 10,
   cols  => 20,
);

isa_ok( $rb, "Tickit::RenderBuffer", '$rb isa Tickit::RenderContext' );

is( $rb->lines, 10, '$rb->lines' );
is( $rb->cols,  20, '$rb->cols' );

# Initially empty
{
   $rb->flush_to_term( $term );
   is_termlog( [],
               'Empty RenderBuffer renders nothing to term' );

   my $cell = $rb->get_cell( 0, 0 );

   ok( $cell, 'get_cell returns a cell' );
   is( $cell->char, undef, '$cell->char is undef' );
}

# Absolute spans
{
   # Direct pen
   my $pen = Tickit::Pen->new( fg => 1 );
   $rb->text_at( 0, 1, "text span", $pen );
   $rb->erase_at( 1, 1, 5, $pen );

   # Stored pen
   $rb->setpen( Tickit::Pen->new( bg => 2 ) );
   $rb->text_at( 2, 1, "another span" );
   $rb->erase_at( 3, 1, 10 );

   # Combined pens
   $rb->text_at( 4, 1, "third span", $pen );
   $rb->erase_at( 5, 1, 7, $pen );

   my $cell = $rb->get_cell( 0, 1 );
   is( chr $cell->char, "t", '$cell->char at 0,1' );
   ok( $cell->pen->equiv( $pen ), '$cell->pen at 0,1' )
      or diag( "Got pen ".$cell->pen.", expected ".$pen );

   is( chr $rb->get_cell( 0, 2 )->char, "e", '$cell->char at 0,2' );

   is( $rb->get_cell( 1, 1 )->char, 0, '$cell->char at 1,1' );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(0,1), SETPEN(fg=>1), PRINT("text span"),
                 GOTO(1,1), SETPEN(fg=>1), ERASECH(5,undef),
                 GOTO(2,1), SETPEN(bg=>2), PRINT("another span"),
                 GOTO(3,1), SETPEN(bg=>2), ERASECH(10,undef),
                 GOTO(4,1), SETPEN(fg=>1,bg=>2), PRINT("third span"),
                 GOTO(5,1), SETPEN(fg=>1,bg=>2), ERASECH(7,undef) ],
               'RenderBuffer renders text to terminal' );

   # cheating
   $rb->setpen( undef );

   $rb->flush_to_term( $term );
   is_termlog( [], 'RenderBuffer now empty after render to terminal' );
}

# UTF-8 handling
{
   my $cols = $rb->text_at( 6, 0, "somé text ĉi tie" );
   is( $cols, 16, '$cols from ->text_at UTF-8' );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(6,0), SETPEN(), PRINT("somé text ĉi tie") ],
               'RenderBuffer renders UTF-8 text' );
}

# Magic handling
{
   my $cols = $rb->text_at( 0, 3, substr "magical Trevor", 0 );
   is( $cols, 14, "return from ->text_at on magical LVALUE" );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(0,3), SETPEN(), PRINT("magical Trevor") ],
               'RenderBuffer correctly gets MAGIC' );
}

# Conversion of numerical arguments - RT120630
{
   tie my $sv, "FetchCounter";
   my $count = 0;
   {
      package FetchCounter;
      sub TIESCALAR { return bless [], shift }
      sub FETCH     { $count++; return "AB"; }
   }

   my $cols = $rb->text_at( 0, 4, $sv );
   is( $cols, 2, "return from ->text_at on SvIV" );

   $rb->goto( 1, 4 );
   $rb->text( $sv );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(0,4), SETPEN(), PRINT("AB"),
                 GOTO(1,4), SETPEN(), PRINT("AB") ],
               'RenderBuffer correctly converts SvIV' );

   cmp_ok( $count, "<=", 2, 'FETCH called no more than twice' );
}

# Span splitting
{
   my $pen = Tickit::Pen->new;
   my $pen2 = Tickit::Pen->new( b => 1 );

   # aaaAAaaa
   $rb->text_at( 0, 0, "aaaaaaaa", $pen );
   $rb->text_at( 0, 3, "AA", $pen2 );

   # BBBBBBBB
   $rb->text_at( 1, 2, "bbbb", $pen );
   $rb->text_at( 1, 0, "BBBBBBBB", $pen2 );

   # cccCCCCC
   $rb->text_at( 2, 0, "cccccc", $pen );
   $rb->text_at( 2, 3, "CCCCC", $pen2 );

   # DDDDDddd
   $rb->text_at( 3, 2, "dddddd", $pen );
   $rb->text_at( 3, 0, "DDDDD", $pen2 );

   $rb->text_at( 4, 4, "", $pen ); # empty text should do nothing

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(0,0), SETPEN(), PRINT("aaa"), SETPEN(b=>1), PRINT("AA"), SETPEN(), PRINT("aaa"),
                 GOTO(1,0), SETPEN(b=>1), PRINT("BBBBBBBB"),
                 GOTO(2,0), SETPEN(), PRINT("ccc"), SETPEN(b=>1), PRINT("CCCCC"),
                 GOTO(3,0), SETPEN(b=>1), PRINT("DDDDD"), SETPEN(), PRINT("ddd") ],
              'RenderBuffer spans can be split' );
}

{
   my $pen = Tickit::Pen->new;
   $rb->text_at( 0, 0, "abcdefghijkl", $pen );
   $rb->text_at( 0, $_, "-", $pen ) for 2, 4, 6, 8;

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(0,0),
                 SETPEN(), PRINT("ab"),
                 SETPEN(), PRINT("-"), # c
                 SETPEN(), PRINT("d"),
                 SETPEN(), PRINT("-"), # e,
                 SETPEN(), PRINT("f"),
                 SETPEN(), PRINT("-"), # g
                 SETPEN(), PRINT("h"),
                 SETPEN(), PRINT("-"), # i
                 SETPEN(), PRINT("jkl") ],
              'RenderBuffer renders overwritten text split chunks' );
}

# Absolute skipping
{
   my $pen = Tickit::Pen->new;
   $rb->text_at( 6, 1, "This will be skipped", $pen );
   $rb->skip_at( 6, 10, 4 );

   $rb->erase_at( 7, 5, 15, $pen );
   $rb->skip_at( 7, 10, 2 );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(6, 1), SETPEN(), PRINT("This will"),
                 GOTO(6,14), SETPEN(), PRINT("skippe"),
                 GOTO(7, 5), SETPEN(), ERASECH(5),
                 GOTO(7,12), SETPEN(), ERASECH(8) ],
              'RenderBuffer skipping' );
}

# VC spans
{
   # Direct pen
   my $pen = Tickit::Pen->new( fg => 3 );
   $rb->goto( 0, 2 ); $rb->text( "text span", $pen );
   $rb->goto( 1, 2 ); $rb->erase( 5, $pen );

   # Stored pen
   $rb->setpen( Tickit::Pen->new( bg => 4 ) );
   $rb->goto( 2, 2 ); $rb->text( "another span" );
   $rb->goto( 3, 2 ); $rb->erase( 10 );

   # Combined pens
   $rb->goto( 4, 2 ); $rb->text( "third span", $pen );
   $rb->goto( 5, 2 ); $rb->erase( 7, $pen );

   $rb->flush_to_term( $term );

   is_termlog( [ GOTO(0,2), SETPEN(fg=>3), PRINT("text span"),
                 GOTO(1,2), SETPEN(fg=>3), ERASECH(5),
                 GOTO(2,2), SETPEN(bg=>4), PRINT("another span"),
                 GOTO(3,2), SETPEN(bg=>4), ERASECH(10),
                 GOTO(4,2), SETPEN(fg=>3,bg=>4), PRINT("third span"),
                 GOTO(5,2), SETPEN(fg=>3,bg=>4), ERASECH(7) ],
              'RenderBuffer renders text' );

   # cheating
   $rb->setpen( undef );
}

# VC Clipping
{
   $rb->goto( -2, 0 ); $rb->text( "above" );
   $rb->goto( 0, -3 ); $rb->text( "left" );
   $rb->goto( 1, 18 ); $rb->text( "right" );
   $rb->goto( 11, 0 ); $rb->text( "below" );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(0, 0), SETPEN(), PRINT("t"),
                 GOTO(1,18), SETPEN(), PRINT("ri") ],
              'RenderBuffer clipping at virtual-cursor' );
}

# VC skipping
{
   my $pen = Tickit::Pen->new;
   $rb->goto( 8, 0 );
   $rb->text( "Some", $pen );
   $rb->skip( 2 );
   $rb->text( "more", $pen );
   $rb->skip_to( 14 );
   $rb->text( "14", $pen );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(8, 0), SETPEN(), PRINT("Some"),
                 GOTO(8, 6), SETPEN(), PRINT("more"),
                 GOTO(8,14), SETPEN(), PRINT("14") ],
              'RenderBuffer skipping at virtual-cursor' );
}

# Translation
{
   $rb->translate( 3, 5 );

   $rb->text_at( 0, 0, "at 0,0", Tickit::Pen->new );

   $rb->goto( 1, 0 );

   is( $rb->line, 1, '$rb->line after translate' );
   is( $rb->col,  0, '$rb->col after translate' );

   $rb->text( "at 1,0", Tickit::Pen->new );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(3,5), SETPEN(), PRINT("at 0,0"),
                 GOTO(4,5), SETPEN(), PRINT("at 1,0") ],
              'RenderBuffer renders text with translation' );
}

# ->eraserect
{
   $rb->eraserect( Tickit::Rect->new( top => 2, left => 3, lines => 5, cols => 8 ) );

   $rb->flush_to_term( $term );
   is_termlog( [ map { GOTO($_,3), SETPEN(), ERASECH(8) } 2 .. 6 ],
              'RenderBuffer renders eraserect' );
}

# Clear
{
   $rb->clear( Tickit::Pen->new( bg => 3 ) );

   $rb->flush_to_term( $term );
   is_termlog( [ map { GOTO($_,0), SETPEN(bg=>3), ERASECH(20) } 0 .. 9 ],
              'RenderBuffer renders clear' );
}

done_testing;
