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

my $PANGO_SCALE;

sub main {
    # Select a font.
    my $font = Text::Layout::FontConfig->from_string("Amiri 60");
    $layout->set_font_description($font);

    # Start...
    my $x = 0;
    my $y = 600;

    # Left align text.
    $layout->set_width( 595 * $PANGO_SCALE );
    $layout->set_alignment("left");

    # Typeset in three parts. Note that parts 1 and 3 will be ltr,
    # and part 2 will be rtl.
    # Note, however, that this currently relies on the native
    # harfbuzz library to correctly determine ('guess') the
    # characteristics of the text.

    $layout->set_markup("abc");
    showlayout( $x, $y );
    $x += ($layout->get_size)[0]/$PANGO_SCALE;

    $layout->set_markup( q{برنامج أهلا بالعالم} );
    showlayout( $x, $y );
    $x += ($layout->get_size)[0]/$PANGO_SCALE;

    $layout->set_markup("xyz");
    showlayout( $x, $y );

    # Typeset as one string, using <span>.
    $x = 0;
    $y -= 100;
    $font = Text::Layout::FontConfig->from_string("Sanss 60");
    $layout->set_font_description($font);
    $layout->set_markup( "abc".
			 "<span font_desc='Amiri'>".q{برنامج أهلا بالعالم}."</span>".
			 "def" );
    showlayout( $x, $y );

    # Ship out.
    $pdf->saveas("pdfapi3.pdf");
}

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
    $fd->register_font( "ITCGaramond-Light.ttf",       "Garamond"               );
    $fd->register_font( "ITCGaramond-Bold.ttf",        "Garamond", "Bold"       );
    $fd->register_font( "ITCGaramond-LightItalic.ttf", "Garamond", "Italic"     );
    $fd->register_font( "ITCGaramond-BoldItalic.ttf",  "Garamond", "BoldItalic" );

    # Make Serif alias for Garamond.
    $fd->register_aliases( "Garamond", "Serif" );

    # Add a Sans family.
    $fd->register_font( "DejaVuSans.ttf",             "Sans"               );
    $fd->register_font( "DejaVuSans-Bold.ttf",        "Sans", "Bold"       );
    $fd->register_font( "DejaVuSans-Oblique.ttf",     "Sans", "Italic"     );
    $fd->register_font( "DejaVuSans-BoldOblique.ttf", "Sans", "BoldItalic" );

    # Add Devanagari (Indian). Requires shaping.
    $fd->register_font( "lohit-devanagari/Lohit-Devanagari.ttf",
			"Deva", "", "", { shaping => 1 } );

    # Add Amiri (Arabic). Requires shaping.
    $fd->register_font( "amiri/amiri-regular.ttf",
			"Amiri", "", "", { shaping => 1 } );

    my $o = { interline => 1 };
    $fd->register_font( "Helvetica", "Sanss", "", "", $o );
    $fd->register_font( "HelveticaOblique", "Sanss", "Italic", "", $o );
    $fd->register_font( "HelveticaBold", "Sanss", "Bold", "", $o );
}

################ Main entry point ################

# Setup the fonts.
setup_fonts();

if ( 1 ) {
    # For compliancy, use Pango units;
    $layout->set_pango_scale;
    $PANGO_SCALE = 1000;
}
else {
    $PANGO_SCALE = 1;
}

main();
