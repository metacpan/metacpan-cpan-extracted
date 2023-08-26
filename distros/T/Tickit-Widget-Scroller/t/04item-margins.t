#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Tickit::Test 0.12;
use Tickit::RenderBuffer;

use Tickit::Widget::Scroller::Item::Text;

my $term = mk_term;

my $item = Tickit::Widget::Scroller::Item::Text->new( "My message here" );

# margin_left
{
   my $item = Tickit::Widget::Scroller::Item::Text->new( "ABCDE " x 10, margin_left => 5 );

   is( $item->height_for_width( 40 ), 2, 'height_for_width 40' );

   my $rb = Tickit::RenderBuffer->new( lines => $term->lines, cols => $term->cols );

   $item->render( $rb, top => 0, firstline => 0, lastline => 1, width => 40, height => 25 );
   $rb->flush_to_term( $term );

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 ERASECH(5,1),
                 SETPEN,
                 PRINT("ABCDE "x5 . "ABCDE"),
                 GOTO(1,0),
                 SETPEN,
                 ERASECH(5,1),
                 SETPEN,
                 PRINT("ABCDE "x4),
                 SETPEN,
                 ERASECH(11) ],
               'Termlog for render margin_left' );

   is_display( [ [TEXT("     ABCDE ABCDE ABCDE ABCDE ABCDE ABCDE")],
                 [TEXT("     ABCDE ABCDE ABCDE ABCDE")]],
               'Display for render margin_left' );
}

# margin_right
{
   my $item = Tickit::Widget::Scroller::Item::Text->new( "ABCDE " x 10, margin_right => 5 );

   is( $item->height_for_width( 40 ), 2, 'height_for_width 40' );

   my $rb = Tickit::RenderBuffer->new( lines => $term->lines, cols => $term->cols );

   $item->render( $rb, top => 0, firstline => 0, lastline => 1, width => 40, height => 25 );
   $rb->flush_to_term( $term );

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("ABCDE "x5 . "ABCDE"),
                 SETPEN,
                 ERASECH(5),
                 GOTO(1,0),
                 SETPEN,
                 PRINT("ABCDE "x4),
                 SETPEN,
                 ERASECH(16) ],
               'Termlog for render margin_right' );

   is_display( [ [TEXT("ABCDE ABCDE ABCDE ABCDE ABCDE ABCDE")],
                 [TEXT("ABCDE ABCDE ABCDE ABCDE")]],
               'Display for render margin_right' );
}

# margin sets both
{
   my $item = Tickit::Widget::Scroller::Item::Text->new( "ABCDE " x 10, margin => 5 );

   is( $item->height_for_width( 40 ), 2, 'height_for_width 40' );

   my $rb = Tickit::RenderBuffer->new( lines => $term->lines, cols => $term->cols );

   $item->render( $rb, top => 0, firstline => 0, lastline => 1, width => 40, height => 25 );
   $rb->flush_to_term( $term );

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 ERASECH(5,1),
                 SETPEN,
                 PRINT("ABCDE "x5),
                 SETPEN,
                 ERASECH(5),
                 GOTO(1,0),
                 SETPEN,
                 ERASECH(5,1),
                 SETPEN,
                 PRINT("ABCDE "x5),
                 SETPEN,
                 ERASECH(5) ],
               'Termlog for render margin' );

   is_display( [ [TEXT("     ABCDE ABCDE ABCDE ABCDE ABCDE")],
                 [TEXT("     ABCDE ABCDE ABCDE ABCDE ABCDE")]],
               'Display for render margin' );
}

# margin excludes pen
{
   $term->clear;
   drain_termlog;

   my $item = Tickit::Widget::Scroller::Item::Text->new( "Red with green BG",
      margin => 10,
      pen => Tickit::Pen->new( fg => "red", bg => "green" )
   );

   $item->height_for_width( 80 );

   my $rb = Tickit::RenderBuffer->new( lines => $term->lines, cols => $term->cols );

   $item->render( $rb, top => 0, firstline => 0, lastline => 0, width => 80, height => 1 );
   $rb->flush_to_term( $term );

   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 ERASECH(10,1),
                 SETPEN(fg=>1,bg=>2),
                 PRINT("Red with green BG"),
                 SETPEN(fg=>1,bg=>2),
                 ERASECH(43,1),
                 SETPEN,
                 ERASECH(10) ],
               'Termlog for render with pen and margin' );
}

done_testing;
