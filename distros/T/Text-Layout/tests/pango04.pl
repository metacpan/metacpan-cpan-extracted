#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Pango;
use Cairo;
require "./pango00.pl";	   # subs

# Create document and graphics environment.
my $surface = Cairo::PdfSurface->create( 'pango04.pdf', 595, 842 ); # A4
my $cr = Cairo::Context->create($surface);
my $layout = Pango::Cairo::create_layout($cr);

# Scale from Cairo (PDF) units to Pango.
my $PANGO_SCALE = Pango->scale;

# Select a font.
my $font = Pango::FontDescription->from_string('AR PL New Sung 60');
$layout->set_font_description($font);
$layout->get_context->set_base_gravity('west');

# Start...
my $x = 0;
my $y = 842-700;

# Left align text.
$layout->set_width( 595 * $PANGO_SCALE );
$layout->set_alignment("left");

# FireFly is TTB.
# WARNING: If the font cannot be found, a substitute font may come out LTR!.
$layout->set_markup("懶惰的姜貓");
$cr->translate(300,100);
$cr->rotate(2*atan2(1,1));
showlayout( $cr, $layout, $x, $y );

# Ship out.
$cr->show_page;
