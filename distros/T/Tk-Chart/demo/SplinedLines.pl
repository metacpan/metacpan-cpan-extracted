#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Chart::Lines;

my $mw = MainWindow->new(
  -title      => 'Tk::Chart::Lines - Spline',
  -background => 'white',
);
my $chart = $mw->Lines(
  -title      => 'bezier curve examples',
  -xlabel     => 'X Label',
  -ylabel     => 'Y Label',
  -background => 'snow',
  -spline     => 1,
  -bezier     => 1,
  -linewidth  => 2,
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th' ],
  [ 10,    30,    20,    30,    5,     41,    1,     23 ],
  [ 10,    5,     10,    0,     17,    2,     40,    23 ],
  [ 20,    10,    12,    20,    30,    10,    35,    12 ],

);

# Add a legend to the graph
my @legends = ( 'legend 1', 'legend 2', 'legend 3' );
$chart->set_legend(
  -title       => 'Title legend',
  -data        => \@legends,
  -titlecolors => 'blue',
);

# Add help identification
$chart->set_balloon();

# Create the graph
$chart->plot( \@data );

MainLoop();
