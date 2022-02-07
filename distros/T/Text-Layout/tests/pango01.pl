#!/usr/bin/perl

# This example created a PDF document using pure Pango. This is
# intended to be a reference for the documents created by the
# tl_p_01.pl test programs.

use strict;
use warnings;
use utf8;

use Pango;
use Cairo;
require "./pango00.pl";	   # subs

# Create document and graphics environment.
my $surface = Cairo::PdfSurface->create( 'pango01.pdf', 595, 842 ); # A4
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
my $txt = qq{ Áhe <i><span foreground="red">quick</span> }.
  # $tinysize = 15360 for a 20pt font.
  qq{<span size="$tinysize"><b>brown</b></span></i> }.
  # rise is in 1/1024 units.
  qq{<span rise="10240">fox</span>}.
  # 10240/1024 units = 10pt.
  qq{<span rise="10pt" }.
  # size=46080 (45*1024) for a 60pt font.
  qq{size="46080">x</span>}.
  # size=45pt for a 60pt font.
  qq{<span rise="10pt" size="45pt">x</span> };
my $txt_nomarkup = "Áhe quick brown fox ";

$layout->set_markup($txt);

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

# Plain Cairo, no Pango.
$cr->select_font_face( "freeserif", "normal", "normal" );
$cr->set_font_size($realfontsize);
$cr->move_to( $x, $y+50 );
$cr->show_text($txt_nomarkup);

$y += 100;

# Right align text.
$layout->set_width( 595 * $PANGO_SCALE );
$layout->set_alignment("center");

# Render it.
showlayout( $cr, $layout, $x, $y );

# Ship out.
$cr->show_page;
