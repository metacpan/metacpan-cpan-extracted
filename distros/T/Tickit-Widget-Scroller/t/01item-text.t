#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test 0.12;
use Tickit::RenderBuffer;

use Tickit::Widget::Scroller::Item::Text;

my $term = mk_term;

my $item = Tickit::Widget::Scroller::Item::Text->new( "My message here" );

isa_ok( $item, "Tickit::Widget::Scroller::Item::Text", '$item' );

is_deeply( [ $item->chunks ],
           [ [ "My message here", 15 ] ],
           '$item->chunks' );

is( $item->height_for_width( 80 ), 1, 'height_for_width 80' );

my $rb = Tickit::RenderBuffer->new( lines => $term->lines, cols => $term->cols );

$item->render( $rb, top => 0, firstline => 0, lastline => 0, width => 80, height => 25 );
$rb->flush_to_term( $term );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("My message here"),
              SETBG(undef),
              ERASECH(65) ],
            'Termlog for render fullwidth' );

is_display( [ [TEXT("My message here")] ],
            'Display for render fullwidth' );

$term->clear;
drain_termlog;

{
   {
      $rb->save;

      $rb->clip( Tickit::Rect->new(
         top   => 0,
         left  => 0,
         lines => 10,
         cols  => 12,
      ) );

      is( $item->height_for_width( 12 ), 2, 'height_for_width 12' );

      $item->render( $rb, top => 0, firstline => 0, lastline => 1, width => 12, height => 10 );

      $rb->restore;
   }

   $rb->flush_to_term( $term );

   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("My message "),
                 SETBG(undef),
                 ERASECH(1),
                 GOTO(1,0),
                 SETPEN,
                 PRINT("here"),
                 SETBG(undef),
                 ERASECH(8) ],
               'Termlog for render width 12' );

   is_display( [ [TEXT("My message")],
                 [TEXT("here")] ],
               'Display for render width 12' );

   my $indenteditem = Tickit::Widget::Scroller::Item::Text->new( "My message here", indent => 4 );

   is( $indenteditem->height_for_width( 12 ), 2, 'height_for_width 12 with indent' );

   $indenteditem->render( $rb, top => 0, firstline => 0, lastline => 1, width => 12, height => 10 );
   $rb->flush_to_term( $term );

   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("My message "),
                 SETBG(undef),
                 ERASECH(1),
                 GOTO(1,0),
                 SETBG(undef),
                 ERASECH(4,1),
                 SETPEN,
                 PRINT("here"),
                 SETBG(undef),
                 ERASECH(4) ],
               'Termlog for render width 12 with indent' );

   is_display( [ [TEXT("My message")],
                 [TEXT("    here")] ],
               'Display for render width 12 with indent' );
}

# Boundary condition in whitespace splitting
{
   $term->clear;
   drain_termlog;

   my $item = Tickit::Widget::Scroller::Item::Text->new( "AAAA BBBB CCCC DDDD" );

   is( $item->height_for_width( 9 ), 2, 'height_for_width 2 for splitting boundary' );

   $item->render( $rb, top => 0, firstline => 0, lastline => 1, width => 9, height => 2 );
   $rb->flush_to_term( $term );

   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("AAAA BBBB"),
                 GOTO(1,0),
                 SETPEN,
                 PRINT("CCCC DDDD") ],
               'Termlog for render splitting boundary' );

   is_display( [ [TEXT("AAAA BBBB")],
                 [TEXT("CCCC DDDD")] ],
               'Display for render splitting boundary' );
}

# Linefeeds
{
   $term->clear;
   drain_termlog;

   my $item = Tickit::Widget::Scroller::Item::Text->new( "Some more text\nwith linefeeds" );

   is_deeply( [ $item->chunks ],
              [ [ "Some more text", 14, linebreak => 1 ],
                [ "with linefeeds", 14 ] ],
              '$item->chunks with linefeeds' );

   is( $item->height_for_width( 80 ), 2, 'height_for_width 2 with linefeeds' );

   $item->render( $rb, top => 0, firstline => 0, lastline => 1, width => 80, height => 2 );
   $rb->flush_to_term( $term );

   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("Some more text"),
                 SETPEN,
                 ERASECH(66),
                 GOTO(1,0),
                 SETPEN,
                 PRINT("with linefeeds"),
                 SETPEN,
                 ERASECH(66) ],
               'Termlog for render with linefeeds' );

   is_display( [ [TEXT("Some more text")],
                 [TEXT("with linefeeds")] ],
               'Display for render with linefeeds' );
}

# Odd Unicode
{
   use utf8;

   $term->clear;
   drain_termlog;

   my $item = Tickit::Widget::Scroller::Item::Text->new( "(ノಠ益ಠ)ノ彡┻━┻" );

   is_deeply( [ $item->chunks ],
              [ [ "(ノಠ益ಠ)ノ彡┻━┻", 15 ] ],
              '$item->chunks with Unicode' );

   is( $item->height_for_width( 80 ), 1, 'height_for_width 2 with Unicode' );

   $item->render( $rb, top => 0, firstline => 0, lastline => 0, width => 80, height => 1 );
   $rb->flush_to_term( $term );

   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("(ノಠ益ಠ)ノ彡┻━┻"),
                 SETPEN,
                 ERASECH(65) ],
               'Termlog for render with Unicode' );

   is_display( [ [TEXT("(ノಠ益ಠ)ノ彡┻━┻")] ],
               'Display for render with Unicode' );
}

done_testing;
