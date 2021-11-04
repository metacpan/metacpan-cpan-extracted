#!/usr/bin/perl

use strict;
use warnings;
use utf8;

my $verbose = 1;

use PDF::API2;

my $pdf = PDF::API2->new;
my $page = $pdf->page;
my $text = $page->text;

#my $font = $pdf->corefont('Times-Roman');
my $font = $pdf->ttfont( $ENV{HOME} . '/.fonts/DejaVuSerif.ttf');
$text->font( $font, 40 );

$text->translate(50,700);
$text->text("the quick brown fox _ ", -underline => ["auto","auto"] );
$text->text("jumps", -underline => ["auto","auto"] );

use lib 'lib';
use Text::Layout;

my $layout = Text::Layout->new($pdf);
# Select a font.
$font = Text::Layout::FontConfig->from_string("Serif 40");
$layout->set_font_description($font);
#$font->set_shaping;

$layout->set_markup( qq{<u>the <s>quick</s> <span underline="double">brown</span> fox _ <span overline="single" overline_color="red">jumps</span></u>} );
$layout->render( 50, 650, $text );

$font->{underline_thickness} = 45;
$font->{underline_position} = -140;
$font->{strikeline_position} = 320;
$font->{overline_position} = 600;
$layout->set_markup( qq{<u>the <s>quick</s> <span underline="double">brown</span> fox _ <span overline="single" overline_color="red">jumps</span></u>} );
$layout->render( 50, 580, $text );



$pdf->saveas("strikes.pdf");

