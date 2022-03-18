#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib "../lib";
use Text::Layout::Markdown;

# Create a layout instance.
my $layout = Text::Layout::Markdown->new;

binmode( STDOUT, ':utf8' );

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
