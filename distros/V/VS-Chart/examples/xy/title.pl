#!/usr/bin/perl

use strict;
use warnings;

use VS::Chart;

my $chart = VS::Chart->new(
    title => "Sample chart", 
);

$chart->render(type => 'xy', as => 'png', to => 'xy_title.png');



