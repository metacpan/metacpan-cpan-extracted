#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;
use Tickit::RenderBuffer;

use String::Tagged;
use Tickit::Widget::Scroller::Item::RichText;

my $term = mk_term;

my $rb = Tickit::RenderBuffer->new( lines => $term->lines, cols => $term->cols );

my $str = String::Tagged->new( "My message here" );
$str->apply_tag(  3, 7, b => 1 );
$str->apply_tag( 11, 4, u => 1 );

my $item = Tickit::Widget::Scroller::Item::RichText->new( $str );

isa_ok( $item, "Tickit::Widget::Scroller::Item::Text", '$item' );

is_deeply( [ $item->chunks ],
           [ [ "My ",     3, pen => Tickit::Pen->new() ],
             [ "message", 7, pen => Tickit::Pen->new( b => 1 ) ],
             [ " ",       1, pen => Tickit::Pen->new() ],
             [ "here",    4, pen => Tickit::Pen->new( u => 1 ) ] ],
           '$item->chunks' );

is( $item->height_for_width( 80 ), 1, 'height_for_width 80' );

$item->render( $rb, top => 0, firstline => 0, lastline => 0, width => 80, height => 25 );
$rb->flush_to_term( $term );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("My "),
              SETPEN(b => 1),
              PRINT("message"),
              SETPEN,
              PRINT(" "),
              SETPEN(u => 1),
              PRINT("here"),
              SETBG(undef),
              ERASECH(65) ],
            'Termlog for render fullwidth' );

is_display( [ [TEXT("My "), TEXT("message",b=>1), BLANK(1), TEXT("here",u=>1)] ],
            'Display for render fullwidth' );

# Linefeeds
{
   $term->clear;
   drain_termlog;

   my $str = String::Tagged->new( "Another message\nwith linefeeds" );
   $str->apply_tag( 8, 12, b => 1 );

   my $item = Tickit::Widget::Scroller::Item::RichText->new( $str );

   is_deeply( [ $item->chunks ],
              [ [ "Another ",    8, pen => Tickit::Pen->new() ],
                [ "message",     7, pen => Tickit::Pen->new( b => 1 ), linebreak => 1 ],
                [ "with",        4, pen => Tickit::Pen->new( b => 1 ) ], 
                [ " linefeeds", 10, pen => Tickit::Pen->new() ] ],
              '$item->chunks with linefeeds' );
}

# Word wrapping on pen changes
{
   $term->clear;
   drain_termlog;

   my $str = String::Tagged->new;
   foreach my $colour (qw( red blue green yellow )) {
      $str->append_tagged( $colour, fg => $colour );
      $str->append( " " );
   }

   my $item = Tickit::Widget::Scroller::Item::RichText->new( $str );

   is( $item->height_for_width( 18 ), 2, 'height_for_width 18 for wrapping pen change' );

   $item->render( $rb, top => 0, firstline => 0, lastline => 1, width => 18, height => 2 );
   $rb->flush_to_term( $term );

   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN(fg=>1),
                 PRINT("red"),
                 SETPEN,
                 PRINT(" "),
                 SETPEN(fg=>4),
                 PRINT("blue"),
                 SETPEN,
                 PRINT(" "),
                 SETPEN(fg=>2),
                 PRINT("green"),
                 SETPEN,
                 PRINT(" "),
                 SETPEN,
                 ERASECH(3),
                 GOTO(1,0),
                 SETPEN(fg=>3),
                 PRINT("yellow"),
                 SETPEN,
                 PRINT(" "),
                 SETPEN,
                 ERASECH(11) ],
               'Termlog for render wrapping pen change' );

   is_display( [ [TEXT("red",fg=>1), BLANK(1), TEXT("blue",fg=>4), BLANK(1), TEXT("green",fg=>2)],
                 [TEXT("yellow",fg=>3)] ],
               'Display for render wrapping pen change' );
}

done_testing;
