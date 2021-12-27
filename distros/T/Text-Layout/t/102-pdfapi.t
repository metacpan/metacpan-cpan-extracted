#! perl

use strict;
use warnings;
use utf8;
use Test::More;
if ( eval { require PDF::API2 } ) {
    plan tests => 32;
}
else {
    plan skip_all => "PDF::API2 not installed";
}

#### All this has been tested.
# Create PDF document, with a page and text content.
my $pdf = PDF::API2->new;
$pdf->mediabox( 595, 842 );	# A4
my $page = $pdf->page;
my $text = $page->text;

# Create a layout.
require Text::Layout;
my $layout = Text::Layout->new($pdf);
isa_ok( $layout, 'Text::Layout::PDFAPI2', 'Implicit backend' );

# Create a FontConfig.
require Text::Layout::FontConfig;
my $fc = Text::Layout::FontConfig->new;
# Register some (core) fonts.
$fc->register_font( "Times-Roman",      "Serif"               );
$fc->register_font( "Times-Bold",       "Serif", "Bold"       );
$fc->register_font( "Times-Italic",     "Serif", "Italic"     );
$fc->register_font( "Times-BoldItalic", "Serif", "BoldItalic" );

# Lookup a font by description.
my $fd = $fc->from_string("Serif 20");
#### End pre-tested setup.

# Apply the font to the layout.
$layout->set_font_description($fd);
is( $layout->get_font_description->to_string, "Serif 20", "Font desc");
# Put some text in the layout.
$layout->set_markup("The quick brows fox");

# Get baseline. Since we're working top-left this is a negative value.
my $v = $layout->get_baseline;
fuzz( $v, -13.66, "baseline $v" );
$v = $layout->get_iter->get_baseline;
fuzz( $v, -13.66, "baseline $v" );

# Get width/height.
my @a = $layout->get_pixel_size;
fuzz( $a[0], 166.08, "pixel_size width $a[0]"  );
fuzz( $a[1], 18.00, "pixel_size height $a[1]" );
my $a = $layout->get_pixel_size;
fuzz( $a->{width}, 166.08, "pixel_size width $a->{width}" );
fuzz( $a->{height}, 18.00, "pixel_size height $a->{height}" );

# get_size should return the same, since we're not using Pango units.
@a = $layout->get_size;
fuzz( $a[0], 166.08, "size width" );
fuzz( $a[1], 18.00, "size height" );
$a = $layout->get_size;
fuzz( $a->{width}, 166.08, "size width" );
fuzz( $a->{height}, 18.00, "size height" );

# Get extents
my @ink = qw( ink layout );
my @fields = qw( x y width height );

my $res = { x => 0.00, y => 0.00, width => 166.08, height => 18.00 };

# This case cannot calculate ink.
my $ink = $res;
my $inkres = [ $res, $ink ];

# Scalar call should yield layout values.
$a = $layout->get_pixel_extents;
for my $f ( @fields ) {
    fuzz( $a->{$f}, $res->{$f},
	  "pixel_extents @{[$ink[1]]} $f @{[$a->{$f}]}" );
}

# List call should yield [ res ink ].
@a = $layout->get_pixel_extents;
for ( 0, 1 ) {
    my $a = $a[$_];
    for my $f ( @fields ) {
	fuzz( $a->{$f}, $inkres->[$_]{$f},
	      "pixel_extents[$_] @{[$ink[$_]]} $f @{[$a->{$f}]}" );
    }
}

# Same, using Pango units (but we do not).
@a = $layout->get_extents;
for ( 0, 1 ) {
    my $a = $a[$_];
    for my $f ( @fields ) {
	fuzz( $a->{$f}, $inkres->[$_]{$f},
	      "extents[$_] @{[$ink[$_]]} $f @{[$a->{$f}]}" );
    }
}

# Big bang?
$layout->show( 100, 500, $text );

sub fuzz { ok( $_[0] < $_[1]+0.01 && $_[0] > $_[1]-0.01, $_[2] ) }
