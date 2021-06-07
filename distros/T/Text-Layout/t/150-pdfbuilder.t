#! perl

use strict;
use warnings;
use utf8;
use Test::More;
if ( eval { require PDF::Builder } ) {
    plan tests => 7;
}
else {
    plan skip_all => "PDF::Builder not installed";
}

# Create PDF document, with a page and text content.
my $pdf = PDF::Builder->new;
ok( $pdf, "Create PDF" );
$pdf->mediabox( 595, 842 );	# A4
my $page = $pdf->page;
ok( $page, "Create PDF page" );
my $text = $page->text;
ok( $text, "Create PDF page text" );

# Create a layout.
require Text::Layout::PDFAPI2;
my $layout = Text::Layout::PDFAPI2->new($pdf);
ok( $layout, "Create layout");

# Create a FontConfig.
require Text::Layout::FontConfig;
my $fc = Text::Layout::FontConfig->new;
ok( $fc, "Get FontConfig" );
# Register some (core) fonts.
$fc->register_font( "Times-Roman",      "Serif"               );
$fc->register_font( "Times-Bold",       "Serif", "Bold"       );
$fc->register_font( "Times-Italic",     "Serif", "Italic"     );
$fc->register_font( "Times-BoldItalic", "Serif", "BoldItalic" );

# Lookup a font by description.
my $fd = $fc->from_string("Serif 20");
isa_ok( $fd, 'Text::Layout::FontDescriptor', "Get font desc" );
isa_ok( $fd->get_font($layout), 'PDF::Builder::Resource::Font::CoreFont', "Get font" );
