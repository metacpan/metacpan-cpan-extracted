#! perl

use strict;
use warnings;
use utf8;
use Test::More;
if ( eval { require PDF::API2 } ) {
    plan tests => 12;
}
else {
    plan skip_all => "PDF::API2 not installed";
}

# Currently the extents method is implemented by the PDFAPI2 backend.
use Text::Layout::PDFAPI2;

-d "t" && chdir("t");

#### All this has been tested.
# Create PDF document, with a page and text content.
my $pdf = PDF::API2->new;

# Create a font.
# Polo-SemiScript was one of the smallest files I could find.
my $fontfile = "Polo-SemiScript.ttf";
ok( -s $fontfile, "have $fontfile" );

my $font;
eval { $font = $pdf->ttfont($fontfile)};
diag($@) if $@;
ok( $font, "have font" );

my $text = "The quick brown fox";

my $e = $font->extents( $text, 64 );
ok( $e, "have extents" );

my $exp = { x     =>   1.6,   y      => -12.16,
	    width => 550.336, height =>  56.96,
	    bl    =>  47.104};

for ( qw( x y width height bl ) ) {
    fuzz( $e->{$_}, $exp->{$_}, "extent $_ $e->{$_}" );
}
augment($exp);
for ( qw( xMin yMin xMax yMax ) ) {
    fuzz( $e->{$_}, $exp->{$_}, "extent $_ $e->{$_}" );
}

# visualize( $text, $e );

sub visualize {
    my ( $txt, $e ) = ( @_ );
    my $text = (my $page = $pdf->page)->text;
    my $gfx = $page->gfx;

    $gfx->translate(50,600);
    $gfx->linewidth(1);
    $gfx->rectxy( $e->{xMin}, $e->{yMin}, $e->{xMax}, $e->{yMax} );
    $gfx->strokecolor("cyan");
    $gfx->stroke;
    $gfx->linewidth(0.5);
    $gfx->rect( $e->{x}, $e->{y}, $e->{width}, $e->{height} );
    $gfx->line( $e->{x}, 0, $e->{x}+$e->{width}, 0 );
    $gfx->strokecolor("magenta");
    $gfx->stroke;

    $text->font($font,64);
    $text->translate(50,600);
    $text->text($txt);

    $pdf->save("200.pdf");
}

sub fuzz { ok( $_[0] < $_[1]+0.01 && $_[0] > $_[1]-0.01, $_[2] ) }

sub augment {
    my $e = shift;
    $e->{xMin} = $e->{x};
    $e->{yMin} = $e->{y};
    $e->{xMax} = $e->{x} + $e->{width};
    $e->{yMax} = $e->{y} + $e->{height};
}
