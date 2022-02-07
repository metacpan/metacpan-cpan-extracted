#!/usr/bin/perl

# This is an example of using Text::Layout to create the same document
# as native Pango.
#
# This example uses Text::Layout in Pango conformance mode. The
# relevant parts of this program and its Pango counterpart are very
# much the same.

use strict;
use warnings;
use utf8;

use lib "../lib";
use PDF::API2;
use Text::Layout;

# Create document and graphics environment.
my $pdf = PDF::API2->new( file => 'tl_p_01.pdf' );
$pdf->mediabox( 595, 842 );	# A4

# Set up page and get the text context.
my $page = $pdf->page;
my $text = $page->text;
my $gfx  = $page->gfx;

# Create a layout instance.
my $layout = Text::Layout->new($pdf);

# Tell Text::Layout that we are running in Pango compatibility.
my $PANGO_SCALE = $layout->set_pango_mode("on");

# Scale from Cairo (PDF) font size to Pango.
my $PANGO_FONT_SCALE = 0.75 * $PANGO_SCALE;

# Font sizes used, scaled.
my $realfontsize = 60;
my $fontsize = $realfontsize * $PANGO_FONT_SCALE;
my $tinysize = 20 * $PANGO_FONT_SCALE;

sub main {

    # Select a font.
    my $font = Text::Layout::FontConfig->from_string("freeserif 12");
    $font->set_size($fontsize);
    $layout->set_font_description($font);

    # Start...
    my $x = 0;
    my $y = 500;		# PDF goes up

    # Text to render.
    my $txt = qq{ Áhe <i><span foreground="red">quick</span> }.
      # $tinysize = 15360 for a 20pt font.
      qq{<span size="$tinysize"><b>brown</b></span></i> }.
      # rise is in 1/1024 units.
      qq{<span rise="10240">fox</span>}.
      # 10240/1024 units = 10pt.
      qq{<span rise="10pt" }.
      # size=46080 for a 60pt font.
      qq{size="46080">x</span>}.
      # size=45pt for a 60pt font.
      qq{<span rise="10pt" size="45pt">x</span> };
    my $txt_nomarkup = "Áhe quick brown fox ";

    $layout->set_markup($txt);

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

    # Plain PDF::API2, no Text::Layout.
    $text->font( $font->{font}, $realfontsize );
    # PDF::API2 text is baseline oriented.
    $text->translate( $x, $y-50 );
    my $dx = $text->text($txt_nomarkup);
    if ( $font->{font}->can("extents") ) {
	my $e = $font->{font}->extents( $txt_nomarkup, $realfontsize );
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

    # Ship out.
    $pdf->save;
}

################ Subroutines ################

sub showlayout {
    my ( $x, $y ) = @_;
    $layout->show( $x, $y, $text);
    $layout->showbb($gfx);
}

sub setup_fonts {
    my $fd = Text::Layout::FontConfig->new;

    # Add font dir and register fonts.
    $fd->add_fontdirs( $ENV{HOME}."/.fonts", "/usr/share/fonts/" );
    for ( "", qw( Bold Italic BoldItalic ) ) {
	$fd->register_font( "FreeSerif$_.ttf", "freeserif", $_,
			  { shaping => 0 } );
    }
    for ( "Roman", qw( Bold Italic BoldItalic ) ) {
	$fd->register_font( "Times-$_", "freeserixf",
			    $_ eq "Roman" ? "" : $_,
			  { shaping => 0 } );
    }
}

################ Main entry point ################

# Setup the fonts.
setup_fonts();

# Run...
main();
