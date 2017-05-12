#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Tickit::Test;

use Tickit::RenderBuffer;

use Tickit::Pen;

my $term = mk_term;

my $rb = Tickit::RenderBuffer->new(
   lines => 10,
   cols  => 20,
);

my $pen = Tickit::Pen->new;

# Absolute characters
{
   $rb->char_at( 5, 5, 0x41, $pen );
   $rb->char_at( 5, 6, 0x42, $pen );
   $rb->char_at( 5, 7, 0x43, $pen );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(5,5),
                 SETPEN, PRINT("A"),
                 SETPEN, PRINT("B"),
                 SETPEN, PRINT("C") ],
               'RenderBuffer renders char_at to terminal' );
}

# Characters setpen
{
   $rb->setpen( Tickit::Pen->new( fg => 6 ) );

   $rb->char_at( 5, 5, 0x44 );
   $rb->char_at( 5, 6, 0x45 );
   $rb->char_at( 5, 7, 0x46 );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(5,5),
                 SETPEN(fg=>6), PRINT("D"),
                 SETPEN(fg=>6), PRINT("E"),
                 SETPEN(fg=>6), PRINT("F") ],
              'RenderBuffer renders char_at' );

   # cheating
   $rb->setpen( undef );
}

# VC characters
{
   $rb->goto( 0, 5 );

   # Direct pen
   $rb->char( 0x47, Tickit::Pen->new( fg => 5 ) );

   # Stored pen
   $rb->setpen( Tickit::Pen->new( bg => 6 ) );
   $rb->char( 0x48 );

   # Combined pens
   $rb->char( 0x49, Tickit::Pen->new( fg => 5 ) );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(0,5),
                 SETPEN(fg=>5), PRINT("G"),
                 SETPEN(bg=>6), PRINT("H"),
                 SETPEN(fg=>5,bg=>6), PRINT("I") ],
               'RenderBuffer renders char at VC' );

   # cheating
   $rb->setpen( undef );
}

# Characters with translation
{
   $rb->translate( 3, 5 );

   $rb->char_at( 1, 1, 0x31, $pen );
   $rb->char_at( 1, 2, 0x32, $pen );

   $rb->flush_to_term( $term );
   is_termlog( [ GOTO(4,6), SETPEN(), PRINT("1"), SETPEN(), PRINT("2") ],
              'RenderBuffer renders char_at with translation' );
}

done_testing;
