#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

plan skip_all => "Convert::Color::XTerm is not available"
   unless eval { require Convert::Color::XTerm };

use Tickit::Test;
use Tickit::RenderBuffer;

use String::Tagged;
use Tickit::Widget::Scroller::Item::RichText;

my $term = mk_term;

my $rb = Tickit::RenderBuffer->new( lines => $term->lines, cols => $term->cols );

# String::Tagged::Formatting conventions
my $str = String::Tagged->new( "plain" )
   ->append_tagged( "b",  bold      => 1 )
   ->append_tagged( "u",  under     => 1 )
   ->append_tagged( "i",  italic    => 1 )
   ->append_tagged( "rv", reverse   => 1 )
   ->append_tagged( "af", monospace => 1 )
   ->append_tagged( "fg", fg => Convert::Color::XTerm->new( "5" ) )
   ->append_tagged( "bg", bg => Convert::Color::XTerm->new( "2" ) )
;

my $item = Tickit::Widget::Scroller::Item::RichText->new_from_formatting( $str );

$item->height_for_width( 80 );

$item->render( $rb, top => 0, firstline => 0, lastline => 0, width => 80, height => 25 );
$rb->flush_to_term( $term );

flush_tickit;

is_termlog( [ GOTO(0,0),
              SETPEN,
              PRINT("plain"),
              SETPEN(b => 1),
              PRINT("b"),
              SETPEN(u => 1),
              PRINT("u"),
              SETPEN(i => 1),
              PRINT("i"),
              SETPEN(rv => 1),
              PRINT("rv"),
              SETPEN(af => 1),
              PRINT("af"),
              SETPEN(fg => 5),
              PRINT("fg"),
              SETPEN(bg => 2),
              PRINT("bg"),
              SETBG(undef),
              ERASECH(64) ],
            'Termlog for render from Formatting' );

is_display( [ [TEXT("plain"), TEXT("b",b=>1), TEXT("u",u=>1), TEXT("i",i=>1), TEXT("rv",rv=>1),
               TEXT("af",af=>1), TEXT("fg",fg=>5), TEXT("bg",bg=>2) ] ],
            'Display for render from Formatting' );

done_testing;
