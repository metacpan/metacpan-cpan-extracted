#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib "../CPAN";
use PDF::API2;

use lib "../lib";
use Text::Layout;
use Text::Layout::FontConfig;

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
    my $font = Text::Layout::FontConfig->from_string("Serif 60");
    $layout->set_font_description($font);

    # Start...
    my $x = 0;
    my $y = 500;

    # Text to render.
    $layout->set_markup( q{Áhe <i><span foreground="red">quick</span> <span size="20"><b>brown</b></span></i> fox} );

    # Right align text.
    $layout->set_width( 595 * $PANGO_SCALE );
    $layout->set_alignment("right");

    # Render it.
    showlayout( $x, $y );

    # Showoff.
    showbb( $x, $y );

    $y -= 100;

    $text->font( $font->{font}, 60);
    $text->translate( $x, $y-50 );
    $text->text(q{Áhe quick brown fox});

    $y -= 100;

    # Text to render.
    $layout->set_markup( q{Áhe quick brown fox} );

    # Right align text.
    $layout->set_width( 595 * $PANGO_SCALE );
    $layout->set_alignment("center");

    # Render it.
    showlayout( $x, $y );

    # Showoff.
    showbb( $x, $y );

    # Ship out.
    $pdf->saveas("pdfapi1.pdf");
}

################ Subroutines ################

my $gfx;

sub showlayout {
    my ( $x, $y ) = @_;
    $layout->show( $x, $y, $text);
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
    printf( "EXT: %.2f %.2f %.2f %.2f\n", @e{qw( x y width height )} );

    # NOTE: Some fonts include natural spacing in the bounding box.
    # NOTE: Some fonts exclude accents on capitals from the bounding box.

    $gfx->save;
    $gfx->translate( $x, $y );
    showloc();

    # Show baseline.
    line( $e{x}, $layout->get_baseline/$PANGO_SCALE, $e{x} + $e{width}, 0, $col );

    # Show bounding box.
    $gfx->linewidth( 0.25 );
    $gfx->strokecolor($col);
    $e{height} = -$e{height};		# PDF coordinates
    $gfx->rectxy( $e{x}, $e{y}, $e{x}+$e{width}, $e{height} );;
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
    $fd->add_fontdirs( $ENV{HOME}."/.fonts" );
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
