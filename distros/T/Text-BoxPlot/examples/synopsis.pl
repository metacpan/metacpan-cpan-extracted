#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Text::BoxPlot;

my $tbp = Text::BoxPlot->new( with_scale => 1 );

say for $tbp->render(
    [ "series A", -2.5, -1,  0, 1,   2.5 ],
    [ "series B", -1,   0,   1, 2,   3.5 ],
    [ "series C", 0,    1.5, 2, 2.5, 5.5 ],
  );

