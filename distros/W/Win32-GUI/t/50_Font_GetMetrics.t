#!perl -wT
# Win32::GUI test suite.
# $Id: 50_Font_GetMetrics.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 7;

use Win32::GUI();

my %font_metrics;

# --------------------------------------------------------------------------
# Test Win32::GUI::Font::GetMetrics() returning the default system font for
# a window created with a custom font size.
#
# Dan Dascalescu
# dandv@users.sourceforge.net
# --------------------------------------------------------------------------

# check that the methods we want to use are available
can_ok('Win32::GUI::Font', qw(new GetMetrics) );

# Create a font of a custom height
my $font_height = 23;

my $font = Win32::GUI::Font->new(
    -name => 'Times New Roman',
    -height => $font_height,
);
isa_ok($font, "Win32::GUI::Font", "\$font");


	# Check FontMetrics works
undef %font_metrics;
%font_metrics = Win32::GUI::Font::GetMetrics($font);
TODO: {
local $TODO = "Win32::GUI::Font::GetMetrics returns metrics for wrong font.  TRACKER:1003427";
is($font_metrics{-height}, $font_height, "GetMetrics gives correct height");
}

# $win_main should be created with a font height of 23
my $W = Win32::GUI::Window->new(
		-font => $font,
);
isa_ok($W, "Win32::GUI::Window", "\$W");

# The Label will inherit $W's font
my $label = $W->AddLabel();
isa_ok($label, "Win32::GUI::Label", "\$label");

# Get the height of $W's font
undef %font_metrics;
%font_metrics = Win32::GUI::Font::GetMetrics($W->GetFont());
TODO: {
local $TODO = "Win32::GUI::Font::GetMetrics returns metrics for wrong font.  TRACKER:1003427";
is($font_metrics{-height}, $font_height, "Window has correct font height");
}

# Get the height of the label's font
undef %font_metrics;
%font_metrics = Win32::GUI::Font::GetMetrics($label->GetFont());
TODO: {
local $TODO = "Win32::GUI::Font::GetMetrics returns metrics for wrong font.  TRACKER:1003427";
is($font_metrics{-height}, $font_height, "Label has correct font height");
}
