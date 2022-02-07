#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use PDF::API2;

use lib "../lib";
use Text::Layout;
use Text::Layout::FontConfig;
eval { require HarfBuzz::Shaper }
  or warn("HarfBuzz::Shaper not found. Expect incorrect results!\n");

# Create document and graphics environment.
my $pdf = PDF::API2->new();
$pdf->mediabox( 595, 842 );	# A4

# Set up page and get the text context.
# Markup::Simple *only* uses the text context, and only for rendering.
my $page = $pdf->page;
my $text = $page->text;

# Create a layout instance.
my $layout = Text::Layout->new($pdf);

# Setup the fonts.
setup_fonts();
# Select a font.
my $font = Text::Layout::FontConfig->from_string("AR-PL-New-Sung 60");
$layout->set_font_description($font);

# Start...
my $x = 200;
my $y = 500;

# Left align text.
$layout->set_width(195);
$layout->set_alignment("left");

my $t = "懶惰的姜貓";
# FireFlySung is TTB.
$layout->set_markup($t);
showlayout( $x, $y );

$x = 0;
$y = 700;
$layout->set_width(595);

$font->set_direction('ltr');
showlayout( $x, $y );

# Ship out.
$pdf->saveas("tl_c_04.pdf");

################ Subroutines ################

my $gfx;

sub showlayout {
    my ( $x, $y ) = @_;
    $layout->show( $x, $y, $text);
    $gfx //= $page->gfx;
    $layout->showbb($gfx);
}

sub setup_fonts {
    # Register all corefonts. Useful for fallback.
    # Not required, skip if you have your own fonts.
    my $fd = Text::Layout::FontConfig->new;
    # $fd->register_corefonts;

    # Add font dir and register fonts.
    $fd->add_fontdirs( $ENV{HOME}."/.fonts", "/usr/share/fonts/" );

    # Add FireFlySung (Chinese). Requires shaping.
    $fd->register_font( "fireflysung.ttf",
			"AR-PL-New-Sung", "", "",
			{ shaping => 1,
			  language => 'chinese',
			  direction => 'ttb',
			  nosubset => 1 } );

}
