#!/usr/local/bin/perl
use warnings;
use strict;
use Text::Echelon;

my $te = Text::Echelon->new();
print $te->makeheader();
