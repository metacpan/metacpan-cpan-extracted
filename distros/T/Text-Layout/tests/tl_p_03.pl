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
my $page = $pdf->page;
my $text = $page->text;

# Create a layout instance.
my $layout = Text::Layout->new($pdf);

my $PANGO_SCALE = $layout->set_pango_mode(1);

# Select a font.
setup_fonts();
my $font = Text::Layout::FontConfig->from_string("Amiri 45");
$layout->set_font_description($font);

# Start...
my $x = 0;
my $y = 700;

# Left align text.
$layout->set_width( 595 * $PANGO_SCALE );
$layout->set_alignment("left");

# Arabic is RTL, so it comes out as right aligned.
$layout->set_markup( q{برنامج أهلا بالعالم} );
showlayout( $x, $y );

# Typeset in three parts. Note that parts 1 and 3 will be ltr,
# and part 2 will be rtl.
# Note, however, that this currently relies on the native
# harfbuzz library to correctly determine ('guess') the
# characteristics of the text.

$y -= 100;

$layout->set_markup("abc");
$x += showlayout( $x, $y );

$layout->set_markup( q{برنامج أهلا بالعالم} );

# Arabic is RTL, restrict to actual width to prevent unwanted alignment.
$layout->set_width( ($layout->get_size)[0] / $PANGO_SCALE );
$x += showlayout( $x, $y );

$layout->set_markup("xyz");
showlayout( $x, $y );

# Typeset as one string, using <span>.
$x = 0;
$y -= 100;
$font = Text::Layout::FontConfig->from_string("Sans 45");
$layout->set_font_description($font);
$layout->set_markup( "abc".
		     "<span font='Amiri'>".q{برنامج أهلا بالعالم}."</span>".
		     "def" );
showlayout( $x, $y );

# Ship out.
$pdf->saveas("tl_p_03.pdf");

################ Subroutines ################

my $gfx;

sub showlayout {
    my ( $x, $y ) = @_;
    $layout->show( $x, $y, $text);
    my $dx = ($layout->get_size)[0] / $PANGO_SCALE;
    $gfx //= $page->gfx;
    $layout->showbb($gfx);
    return $dx;
}

sub setup_fonts {
    my $fd = Text::Layout::FontConfig->new;

    # Add font dir and register fonts.
    $fd->add_fontdirs( $ENV{HOME}."/.fonts", "/usr/share/fonts/" );

    # Add a Sans family.
    $fd->register_font( "FreeSans.ttf",            "Sans"               );
    $fd->register_font( "FreeSansBold.ttf",        "Sans", "Bold"       );
    $fd->register_font( "FreeSansOblique.ttf",     "Sans", "Italic"     );
    $fd->register_font( "FreeSansBoldOblique.ttf", "Sans", "BoldItalic" );

    # Add Devanagari (Indian). Requires shaping.
    $fd->register_font( "lohit-devanagari/Lohit-Devanagari.ttf",
			"Deva", "", "", { shaping => 1 } );

    # Add Amiri (Arabic). Requires shaping.
    $fd->register_font( "amiri/amiri-regular.ttf",
			"Amiri", "", "",
			{ shaping => 1,
			  nosubset => 1,
			} );
}
