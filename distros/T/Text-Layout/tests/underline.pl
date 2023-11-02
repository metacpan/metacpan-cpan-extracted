#!/usr/bin/perl

use strict;
use warnings;
use utf8;

my $verbose = 1;

use PDF::API2;

my $pdf = PDF::API2->new;
my $page = $pdf->page;
my $text = $page->text;

my $font = $pdf->corefont('Times-Roman');
$text->font( $font, 80 );

$text->translate(50,700);
$text->text("the quick brown fox _ ", -underline => ["auto","auto"] );
$text->text("jumps", -underline => "auto" );

use lib 'lib';
use Text::Layout;

my $layout = Text::Layout->new($pdf);
#my $fc = Text::Layout::FontConfig->new( corefonts => 1 );
# Select a font.
$font = Text::Layout::FontConfig->from_string("Times 80");
#my $font = $fc->from_string("Times 60");
$layout->set_font_description($font);
#$font->set_shaping;
$font->{underline_thickness} = 45;
$font->{underline_position} = -100;
$layout->set_markup( qq{<u>the <s>quick</s> <span underline="double" underline_color="red">brown</span> fox _ jumps</u>} );
$layout->render( 50, 650, $text );
$layout->set_markup( qq{the <span bgcolor='yellow'>quick</span> brown fox _ jumps} );
$layout->render( 50, 550, $text );


$pdf->saveas("underline.pdf");

