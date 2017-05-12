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

my $pen = Tickit::Pen->new;

# position
{
   $rb->goto( 2, 2 );

   {
      $rb->save;

      $rb->goto( 4, 4 );

      is( $rb->line, 4, '$rb->line before restore' );
      is( $rb->col,  4, '$rb->col before restore' );

      $rb->restore;
   }

   is( $rb->line, 2, '$rb->line after restore' );
   is( $rb->col,  2, '$rb->col after restore' );

   $rb->text( "some text", $pen );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(2,2), SETPEN(), PRINT("some text") ],
              'Stack saves/restores virtual cursor position' );
}

# clipping
{
   $rb->text_at( 0, 0, "0000000000", $pen );

   {
      $rb->save;
      $rb->clip( Tickit::Rect->new( top => 0, left => 2, lines => 10, cols => 16 ) );

      $rb->text_at( 1, 0, "1111111111", $pen );

      $rb->restore;
   }

   $rb->text_at( 2, 0, "2222222222", $pen );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(0,0), SETPEN(), PRINT("0000000000"),
                 GOTO(1,2), SETPEN(), PRINT("11111111"),
                 GOTO(2,0), SETPEN(), PRINT("2222222222") ],
              'Stack saves/restores clipping region' );
}

# pen
{
   $rb->save;
   {
      $rb->goto( 3, 0 );

      $rb->setpen( Tickit::Pen->new( bg => 1 ) );
      $rb->text( "123" );

      {
         $rb->savepen;

         $rb->setpen( Tickit::Pen->new( fg => 4 ) );
         $rb->text( "456" );

         $rb->setpen( Tickit::Pen->new( bg => -1 ) );

         $rb->text( "789" );

         $rb->restore;
      }

      $rb->text( "ABC" );
   }
   $rb->restore;

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(3,0),
                 SETPEN(bg=>1), PRINT("123"),
                 SETPEN(bg=>1,fg=>4), PRINT("456"),
                 SETPEN(), PRINT("789"),
                 SETPEN(bg=>1), PRINT("ABC") ],
              'Stack saves/restores render pen' );

   $rb->save;
   {
      $rb->goto( 4, 0 );

      $rb->setpen( Tickit::Pen->new( rv => 1 ) );
      $rb->text( "123" );

      {
         $rb->savepen;

         $rb->setpen( Tickit::Pen->new( rv => 0 ) );
         $rb->text( "456" );

         $rb->restore;
      }

      $rb->text( "789" );
   }
   $rb->restore;

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(4,0),
                 SETPEN(rv=>1), PRINT("123"),
                 SETPEN(), PRINT("456"),
                 SETPEN(rv=>1), PRINT("789") ],
              'Stack saves/restores allows zeroing pen attributes' );
}

# translation
{
   $rb->text_at( 0, 0, "A", $pen );

   $rb->save;
   {
      $rb->translate( 2, 2 );

      $rb->text_at( 1, 1, "B", $pen );
   }
   $rb->restore;

   $rb->text_at( 2, 2, "C", $pen );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(0,0), SETPEN(), PRINT("A"),
                 GOTO(2,2), SETPEN(), PRINT("C"),
                 GOTO(3,3), SETPEN(), PRINT("B") ],
              'Stack saves/restores translation offset' );
}

done_testing;
