#!/usr/bin/perl

use strict;
use warnings;
use utf8;

binmode( STDOUT => ':utf8' );
binmode( STDERR => ':utf8' );

use PDF::API2;

use lib "../lib";
use Text::Layout;
use Text::Layout::FontConfig;

# Create document and graphics environment.
my $pdf = PDF::API2->new();
$pdf->mediabox( 595, 842 );	# A4

# Set up page and get the text context.
my $page = $pdf->page;
my $text = $page->text;
my $gfx  = $page->gfx;

# Create a layout instance.
my $layout = Text::Layout->new($pdf);

# Setup the fonts.
setup_fonts();

# Select a font.
my $font = Text::Layout::FontConfig->from_string("Sans 45");
$layout->set_font_description($font);
$layout->register_element
  ( TextLayoutImageElement->new( pdf => $pdf ), "img" );

# Start...
my $x = 0;
my $y = 730;

#=for later

# Text to render.
$layout->set_markup("abc<img src=ab.jpg />def");
showlayout( $x, $y );
$layout->set_markup("abc<img src=ab.jpg dx=10/>def");
showlayout( $x+300, $y );

$y -= 150;

$layout->set_markup("abc<img src=ab.jpg dy=-40 scale=0.8/>def");
showlayout( $x, $y );
$layout->set_markup("abc<img src=ab.jpg dx=10 dy=-40 scale=0.8/>def");
showlayout( $x+300, $y );

$y -= 150;

$layout->set_markup("abc<img src=ab.jpg dx=-20 dy=30 width=40 height=80 h=0 w=0/>def");

# Render it.
showlayout( $x, $y );

$y -= 150;

#=cut

# Make a non-zero origin object.
my $xo = $pdf->xo_form;
$xo->fill_color("lime");
$xo->stroke_color("green");
$xo->linewidth(2);
$xo->bbox( -10, -10, 30, 70);
$xo->transform( translate => [ -10, -10 ] );
$xo->rectangle(0,0,40,80);
$xo->fill;
$xo->move(10,0)->vline(80)->stroke;
$xo->move(0,10)->hline(40)->stroke;

my $dd = "";
$layout->set_markup("abc<img src=xo $dd/>def");
showlayout( $x, $y );
$layout->set_markup("abc<img src=xo $dd bbox=1/>def");
showlayout( $x+300, $y );
$y -= 150;
$dd = "dx=10 dy=10";
$layout->set_markup("abc<img src=xo $dd/>def");
showlayout( $x, $y );
$layout->set_markup("abc<img src=xo $dd bbox=1/>def");
showlayout( $x+300, $y );
$y -= 150;


$pdf->saveas("pdfapi2.pdf");

################ Subroutines ################

sub showlayout {
    my ( $x, $y ) = @_;
    $y -= $layout->get_baseline;
    $layout->show( $x, $y, $text);
    $layout->showbb($gfx);
}

sub setup_fonts {
    # Register all corefonts. Useful for fallback.
    # Not required, skip if you have your own fonts.
    my $fd = Text::Layout::FontConfig->new;
    # $fd->register_corefonts;

    $fd->add_fontdirs( $ENV{HOME}."/.fonts", "/usr/share/fonts/" );

    $fd->register_font( "ITCGaramond-Light.ttf",       "Garamond"               );
    $fd->register_font( "ITCGaramond-Bold.ttf",        "Garamond", "Bold"       );
    $fd->register_font( "ITCGaramond-LightItalic.ttf", "Garamond", "Italic"     );
    $fd->register_font( "ITCGaramond-BoldItalic.ttf",  "Garamond", "BoldItalic" );

    # Make Serif alias for Garamond.
    $fd->register_aliases( "Garamond", "Serif" );

    # Add a Sans family.
    $fd->register_font( "DejaVuSans.ttf",             "Sans",  "",
			{ shaping => 0 }
		      );
    $fd->register_font( "DejaVuSans-Bold.ttf",        "Sans", "Bold"       );
    $fd->register_font( "DejaVuSans-Oblique.ttf",     "Sans", "Italic"     );
    $fd->register_font( "DejaVuSans-BoldOblique.ttf", "Sans", "BoldItalic" );

    # Add a Sans family.
    $fd->register_font( "calibri.ttf",   "Cal",  "", 	      );
    $fd->register_font( "calibrib.ttf",  "Cal", "Bold"       );
    $fd->register_font( "calibri.ttf",  "Cal", "Italic"     );
    $fd->register_font( "calibrii.ttf", "Cal", "BoldItalic" );
}

################ Classes ################

use Object::Pad;

class TextLayoutImageElement :isa(Text::Layout::PDFAPI2::ImageElement);

method getimage ($fragment) {
    $fragment->{_img} //=
      do {
	  if ( $fragment->{src} eq "xo" ) {
	      $xo;
	  }
	  else {
	      $pdf->image($fragment->{src});
	  }
      };
}

1;
