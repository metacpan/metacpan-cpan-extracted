#!/usr/bin/perl

use strict;
use warnings;

use VS::Chart;

# Create charting object
my $chart = VS::Chart->new();

# Add some random data for 
my @v = map { 2+ rand 5 } 0..3;
for (0..99) {
    @v = map { $_ + rand(0.5) - 0.25 } @v;
    $chart->add(@v);
}

$chart->_dataset(0)->set("line_dash" => 5);

$chart->render(type => 'line', as => 'png', to => 'lines_basic.png');
