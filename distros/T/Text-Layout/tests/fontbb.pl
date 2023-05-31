#!/usr/bin/perl

use v5.36;
use Object::Pad;
use utf8;

my $verbose = 1;

@ARGV = ( "Times-Roman",
	  "FreeSerif.ttf",
	  "DejaVuSerif.ttf",
	  "ArialMT.ttf",
	  "MuseJazzText.otf",
	  "MuseJazzChord.ttf" ) unless @ARGV;

use PDF::API2;

sub max { $_[0] >= $_[1] ? $_[0] : $_[1] }
sub min { $_[0] <= $_[1] ? $_[0] : $_[1] }

my $pdf  = PDF::API2->new;
my $page = $pdf->page;
my $gfx  = $page->gfx;

PDF::API2::addFontDirs( $ENV{HOME}."/.fonts", "/usr/share/fonts/" );

my $x0 = 70;
my $y0 = 650;

# Annotations.
my $af = $pdf->font("Helvetica");
my $as = 8;

my $scale = 0.08;
my $dx = 3000 * $scale;
my $dy = 2500 * $scale;
my $sz = 1000 * $scale;
my $dd =  400 * $scale;

my ( $x, $y ) = ( $x0, $y0 );

for my $fn ( @ARGV ) {

    next unless $fn;

    my $font = $pdf->font($fn);
    # PDF::API2 units are 1/1000 em.
    my @xbb = $font->fontbbox;
    push( @xbb, $font->ascender, $font->descender );
    my $xbb = sprintf( "%d %d | %d %d | %d %d", @xbb );
    warn("$fn: $xbb\n");

    # Scale.
    my @bb = map { $_ * $scale } @xbb;
    my $o = $pdf->xo_form;

    $o->line_width(0.5);
    $o->fill_color('black');
    $o->stroke_color('black');

    # Background (first glyph).
    $o->fill_color("yellow");
    $o->rectangle( 0, $bb[1],
		   $sz*$font->width("Á"), $bb[3] );
    $o->fill;

    # Crosslines for origin.
    $o->stroke_color('lightgreen');
    $o->move( -$dd, 0 );
    $o->hline($dd);
    $o->stroke;
    $o->move( 0, -$dd );
    $o->vline($dd);
    $o->stroke;

    # Font bounding box.
    $o->stroke_color("blue");
    $o->fill_color("blue");
    $o->rectangle(@bb[0..3]);
    $o->stroke;
    $o->textstart;
    $o->font( $af, $as );
    $o->translate( $bb[0]+1, $bb[3]+3 );
    $o->text("bounding box");
    $o->translate( $bb[0]+1, $bb[1]-8 );
    $o->text("$xbb[0] $xbb[1]  $fn");
    $o->translate( $bb[2], $bb[3]+3 );
    $o->text("$xbb[2] $xbb[3]", align => "right" );
    $o->textend;

    # Ascender and descender.
    $o->stroke_color("red");
    $o->fill_color("red");
    $o->move( -$dd, $bb[4] );
    $o->hline( $bb[2]+$dd );
    $o->stroke;
    $o->move( -$dd, $bb[5]  );
    $o->hline( $bb[2]+$dd );
    $o->stroke;
    $o->textstart;
    $o->font( $af, $as );
    $o->translate( $bb[2]+$dd, $bb[4]+2 );
    $o->text( "ascender", align => "right" );
    $o->translate( $bb[2]+$dd, $bb[4]-8 );
    $o->text( $xbb[4], align => "right" );
    $o->translate( $bb[2]+$dd, $bb[5]+2 );
    $o->text( "descender", align => "right" );
    $o->translate( $bb[2]+$dd, $bb[5]-8 );
    $o->text( $xbb[5], align => "right" );
    $o->textend;

    # Sample glyphs (with max asc and desc).
    $o->fill_color("black");
    $o->stroke_color("black");
    $o->textstart;
    $o->font( $font, $sz );
    $o->translate( 0, 0 );
    $o->text( "Ág" );
    $o->textend;
    my @obb = ( min($bb[0],-$dd), $bb[1]-10, $bb[2]+$dd, $bb[3]+9 );
#    $o->rectangle(@obb); $o->stroke;
    $o->bbox(@obb);

    if ( $x + $bb[2] + $dd > 590 ) {
	$x = $x0;
	$y -= $dy;
    }

    warn("X: [@{[$o->bbox]}] @ $x,$y\n");
    $gfx->object( $o, $x, $y, 1, 1 );
    $x += $dx;

}

$pdf->saveas("fontbb.pdf");
