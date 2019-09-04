#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib "../lib";
use Text::Layout;
use Text::Layout::FontConfig;

# Create a layout instance.
my $layout = Text::Layout->new;

binmode( STDOUT, ':utf8' );

sub main {
    # Select a font.
    my $font = Text::Layout::FontConfig->from_string("Serif 60");
    $layout->set_font_description($font);

    # Text to render.
    $layout->set_markup( q{Áhe <i><span foreground="red">quick</span> <span size="20"><b>brown</b></span></i> fox} );

    # Render it.
    print $layout->show(), "\n";

    # Text to render.
    $layout->set_markup( q{Áhe quick brown fox} );

    # Right align text (will be ignored w/ Markdown).
    $layout->set_width(50);
    $layout->set_alignment("center");

    # Render it.
    print $layout->show(), "\n";

}

sub setup_fonts {
    # Register all corefonts. Useful for fallback.
    Text::Layout::FontConfig->register_corefonts;
}

################ Main entry point ################

# Setup the fonts.
setup_fonts();

main();
