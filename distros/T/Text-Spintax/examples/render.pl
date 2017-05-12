#!/usr/bin/perl

use Text::Spintax;
use strict;

my $rendernode = Text::Spintax->new->parse("This {is|was} {a text|an example|a demo}");
foreach (1 .. 10) {
   printf "%s\n",$rendernode->render;
}
