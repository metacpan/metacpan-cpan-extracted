#! perl

use strict;
use warnings;
use utf8;
use Test::More;
if ( eval { require PDF::API2 } ) {
    plan tests => 27;
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
ok( $v > -13.67 && $v < -13.65, "baseline $v" );
$v = $layout->get_iter->get_baseline;
ok( $v > -13.67 && $v < -13.65, "baseline $v" );

# Get width/height.
my @a = $layout->get_pixel_size;
ok( $a[0] > 166.07 && $a[0] < 166.09, "pixel_size width $a[0]"  );
ok( $a[1] >  17.99 && $a[1] <  18.01, "pixel_size height $a[1]" );
my $a = $layout->get_pixel_size;
ok( $a->{width}  > 166.07 && $a->{width}  < 166.09, "pixel_size width $a->{width}" );
ok( $a->{height} >  17.99 && $a->{height} <  18.01, "pixel_size height $a->{height}" );

# get_size should return the same, since we're not using Pango units.
@a = $layout->get_size;
ok( $a[0] > 166.07 && $a[0] < 166.09, "size width" );
ok( $a[1] >  17.99 && $a[1] <  18.01, "size height" );
$a = $layout->get_size;
ok( $a->{width}  > 166.07 && $a->{width}  < 166.09, "size width" );
ok( $a->{height} >  17.99 && $a->{height} <  18.01, "size height" );

# Get extents
my @ink = qw( ink layout );
@a = $layout->get_pixel_extents;
for ( 0, 1 ) {
    my $a = $a[$_];
    ok( $a->{x} > -0.01 && $a->{x} < 0.01,
	"pixel_extents @{[$ink[$_]]} x @{[$a->{x}]}" );
    ok( $a->{y} > -0.01 && $a->{y} < 0.01,
	"pixel_extents @{[$ink[$_]]} y @{[$a->{y}]}" );
    ok( $a->{width}  > 166.07 && $a->{width}  < 166.09,
	"pixel_extents @{[$ink[$_]]} width @{[$a->{width}]}" );
    ok( $a->{height} >  17.99 && $a->{height} <  18.01,
	"pixel_extents @{[$ink[$_]]} height @{[$a->{height}]}" );
}
# Same, using Pango units (but we do not).
@a = $layout->get_extents;
for ( 0, 1 ) {
    my $a = $a[$_];
    ok( $a->{x} > -0.01 && $a->{x} < 0.01,
	"extents @{[$ink[$_]]} x @{[$a->{x}]}" );
    ok( $a->{y} > -0.01 && $a->{y} < 0.01,
	"extents @{[$ink[$_]]} y @{[$a->{y}]}" );
    ok( $a->{width}  > 166.07 && $a->{width}  < 166.09,
	"extents @{[$ink[$_]]} width @{[$a->{width}]}" );
    ok( $a->{height} >  17.99 && $a->{height} <  18.01,
	"extents @{[$ink[$_]]} height @{[$a->{height}]}" );
}

# Big bang?
$layout->show( 100, 500, $text );
