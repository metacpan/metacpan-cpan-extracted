#!/usr/bin/perl
use strict;
use warnings;
use Tk;

use Tk::Chart::Boxplots;

my $mw = MainWindow->new(
  -title      => 'Tk::Chart::Boxplots',
  -background => 'white',
);

my $chart = $mw->Boxplots(
  -title             => 'Tk::Chart::Boxplots module',
  -interval          => 1,
  -background        => 'black',
  -textcolor         => 'white',
  -axiscolor         => 'white',
  -valuescolor       => 'white',
  -boxplotlinescolor => 'white',
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th' ],
  [ [ 100 .. 125, 136 .. 140 ],
    [ 22 .. 89 ],
    [ 12, 54, 88, 10 ],
    [ 12,      11, 23, 14 .. 98, 45 ],
    [ 0 .. 55, 11, 12 ]
  ],
  [ [ -25 .. -5, 1 .. 15 ],
    [ -45, 25 .. 45, 100 ],
    [ 70,  42 .. 125 ],
    [ 100, 30, 50 .. 78, 88, ],
    [ 180 .. 250 ]
  ],

);

# Add a legend to the graph
my @legends = ( 'data 1', 'data 2' );
$chart->set_legend(
  -title       => 'My boxplots data',
  -data        => \@legends,
  -titlecolors => 'white',
  -legendcolor => 'white',
  -box         => 1,
);

# Add help identification
$chart->set_balloon();

# Create the graph
$chart->plot( \@data );

my $one     = [ 210 .. 275 ];
my $two     = [ 180, 190, 200, 220, 235, 245 ];
my $three   = [ 40, 140 .. 150, 160 .. 180, 250 ];
my $four    = [ 100 .. 125, 136 .. 140 ];
my $five    = [ 10 .. 50, 100, 180 ];
my @new_data = ( $one, $two, $three, $four, $five );

$chart->add_data( \@new_data, 'data 3' );

MainLoop();
