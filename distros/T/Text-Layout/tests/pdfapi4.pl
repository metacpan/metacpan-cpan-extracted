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
    showbb( $x, $y );
    $x += ($layout->get_size)[0]/$PANGO_SCALE;

    my $lrm = "\x{200e}";
    my $rlm = "\x{200f}";

    my $t = join(" ",
		 qq{ساعة},
		 qq{24},
		 qq{في},
		 qq{Perl},
		 qq{تعلم},
		);
    $layout->set_markup($t);
    showlayout( $x, $y );
    showbb( $x, $y );
    $x += ($layout->get_size)[0]/$PANGO_SCALE;

    $layout->set_markup("xyz");
    showlayout( $x, $y );
    showbb( $x, $y );

    # Typeset as one string, using <span>.
    $x = 0;
    $y -= 100;
    $font = Text::Layout::FontConfig->from_string("Sanss 60");
    $layout->set_font_description($font);
    $layout->set_markup( "abc".
			 "<span font_desc='Amiri'>".q{تعلم 48 في 24 ساعة}."!</span>".
			 "def" );
    showlayout( $x, $y );
    showbb( $x, $y );

    # Ship out.
    $pdf->saveas("pdfapi4.pdf");
}

################ Subroutines ################

my $gfx;

sub showlayout {
    my ( $x, $y ) = @_;
    $layout->show( $x, $y, $text );
}

sub showloc {
    my ( $x, $y, $d, $col ) = @_;
    $x ||= 0; $y ||= 0; $d ||= 50; $col ||= "blue";
    $gfx //= $page->gfx;

    line( $x-$d, $y, 2*$d, 0, $col );
    line( $x, $y-$d, 0, 2*$d, $col );
}

sub showbb {
    my ( $x, $y, $col ) = @_;
    $col ||= "magenta";
    $gfx //= $page->gfx;

    # Bounding box, top-left coordinates.
    my %e = %{($layout->get_pixel_extents)[1]};
    # printf( "EXT: %.2f %.2f %.2f %.2f\n", @e{qw( x y width height )} );

    # NOTE: Some fonts include natural spacing in the bounding box.
    # NOTE: Some fonts exclude accents on capitals from the bounding box.

    $gfx->save;
    $gfx->translate( $x, $y );
    showloc();

    # Show baseline.
    line( $e{x}, $layout->get_baseline/$PANGO_SCALE, $e{width}-$e{x}, 0, $col );

    # Show bounding box.
    $gfx->linewidth( 0.25 );
    $gfx->strokecolor($col);
    $e{height} = -$e{height};		# PDF coordinates
    $gfx->rectxy( $e{x}, $e{y}, $e{width}, $e{height} );;
    $gfx->stroke;
    $gfx->restore;
}

sub line {
    my ( $x, $y, $w, $h, $col ) = @_;
    $col ||= "black";
    $gfx //= $page->gfx;

    $gfx->save;
    $gfx->move( $x, $y );
    $gfx->line( $x+$w, $y+$h );
    $gfx->linewidth(0.5);
    $gfx->strokecolor($col);
    $gfx->stroke;
    $gfx->restore;
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
