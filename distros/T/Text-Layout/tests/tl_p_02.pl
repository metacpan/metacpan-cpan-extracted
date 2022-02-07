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
my $gfx  = $page->gfx;

# Create a layout instance.
my $layout = Text::Layout->new($pdf);

my $PANGO_SCALE = $layout->set_pango_mode("on");

# Setup the fonts.
setup_fonts();

# Select a font.
my $font = Text::Layout::FontConfig->from_string("Sans 33");
$layout->set_font_description($font);

# Start...
my $x = 0;
my $y = 700;

# Text to render.
$layout->set_markup( q{ Áhe <i><span foreground="red">quick</span> <span size="15360"><b>brown</b></span></i> fox } );

# Left align text.
$layout->set_width( 595 * $PANGO_SCALE );
$layout->set_alignment("left");

# Render it.
showlayout( $x, $y );

$y -= 100;

# Right align text.
$layout->set_width( 595 * $PANGO_SCALE );
$layout->set_alignment("right");

# Render it.
showlayout( $x, $y );

$y -= 100;

$text->font( $font->{font}, 44 );
$text->translate( $x, $y-50 );
my $txt_nomarkup = q{Áhe quick brown fox};
my $dx = $text->text($txt_nomarkup);
if ( $font->{font}->can("extents") ) {
    my $e = $font->{font}->extents( $txt_nomarkup, 44 );
    printf( "EXT: %.2f %.2f %.2f %.2f\n", @$e{qw( x y width height )} );
    $gfx->save;
    $gfx->translate( $x, $y-50 );
    # PDF::API2 text is baseline oriented, so are the extents.
    # So we can draw the BB at the same origin as the text.
    $gfx->rect( $e->{x}, $e->{y}, $e->{width}, $e->{height} );
    $gfx->linewidth(0.5);
    $gfx->strokecolor("cyan");
    $gfx->stroke;
    $gfx->restore;
}
# Draw baseline.
$gfx->save;
$gfx->translate( $x, $y-50 );
$gfx->move( 0, 0 );
$gfx->line( $dx, 0 );
$gfx->linewidth(0.5);
$gfx->strokecolor("magenta");
$gfx->stroke;
$gfx->restore;

$y -= 100;

# Right align text.
$layout->set_width( 595 * $PANGO_SCALE );
$layout->set_alignment("center");

# Render it.
showlayout( $x, $y );

$y -= 100;

# This will only work properly with the HarfBuzz driver.
$font = Text::Layout::FontConfig->from_string("Deva 45");
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
  qq{ <span font="sans 20"> this should look like THIS};
$layout->set_markup($phrase);
showlayout( $x, $y );

# Ship out.
$pdf->saveas("tl_p_02.pdf");

################ Subroutines ################

sub showlayout {
    my ( $x, $y ) = @_;
    $layout->show( $x, $y, $text);
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

    # Add Devanagari. Requires shaping.
    # Note that Nepali is a LTR language.
    $fd->register_font( "lohit-devanagari/Lohit-Devanagari.ttf",
			"Deva", "", "",
			{ shaping => 1,
			  language => 'nepali'
			} );

    my $o = { interline => 1 };
    $fd->register_font( "Helvetica", "Sanss", "", "", $o );
    $fd->register_font( "HelveticaOblique", "Sanss", "Italic", "", $o );
    $fd->register_font( "HelveticaBold", "Sanss", "Bold", "", $o );
}
