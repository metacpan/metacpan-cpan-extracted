#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Pango;
use Cairo;
require "./pango00.pl";	   # subs

# Create document and graphics environment.
my $surface = Cairo::PdfSurface->create( 'pango02.pdf', 595, 842 ); # A4
my $cr = Cairo::Context->create($surface);
my $layout = Pango::Cairo::create_layout($cr);

# Scale from Cairo (PDF) units to Pango.
my $PANGO_SCALE = Pango->scale;

# Scale from Cairo (PDF) font size to Pango.
my $PANGO_FONT_SCALE = 0.75 * $PANGO_SCALE;

# Font sizes used, scaled.
my $realfontsize = 60;
my $fontsize = $realfontsize * $PANGO_FONT_SCALE;
my $tinysize = 20 * $PANGO_FONT_SCALE;

# Select a font.
my $font = Pango::FontDescription->from_string('freeserif 12');
$font->set_size($fontsize);
$layout->set_font_description($font);

# Start...
my $x = 0;
my $y = 842-500;		# Cairo goes down

# Text to render.
$layout->set_markup( q{ Áhe <i><span foreground="red">quick</span> <span size="15360"><b>brown</b></span></i> fox } );

# Left align text.
$layout->set_width( 595 * $PANGO_SCALE );
$layout->set_alignment("left");

# Render it.
showlayout( $cr, $layout, $x, $y );

$y += 100;

# Right align text.
$layout->set_width( 595 * $PANGO_SCALE );
$layout->set_alignment("right");

# Render it.
showlayout( $cr, $layout, $x, $y );

$y += 100;

$font = Pango::FontDescription->from_string('Lohit Devanagari 45');
$layout->set_font_description($font);
$layout->set_width( 595 * $PANGO_SCALE );
# Nepali is LTR.
$layout->set_alignment("left");

# This text consists of 6 characters but will render 4 glyphs.
my $phrase =
  "\N{DEVANAGARI LETTER TA}".
  "\N{DEVANAGARI LETTER MA}".
  "\N{DEVANAGARI VOWEL SIGN AA}".
  "\N{DEVANAGARI LETTER NGA}".
  "\N{DEVANAGARI SIGN VIRAMA}".
  "\N{DEVANAGARI LETTER GA}".
  qq{ <span font="sans 20"> this should look like THIS</span>};
$layout->set_markup($phrase);
showlayout( $cr, $layout, $x, $y );

# Ship out.
$cr->show_page;
