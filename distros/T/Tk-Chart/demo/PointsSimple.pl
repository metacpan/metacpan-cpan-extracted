#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Chart::Lines;

my $mw = MainWindow->new(
  -title      => 'Tk::Chart::Points',
  -background => 'white',
);
my $chart = $mw->Lines(
  -title      => 'Tk::Chart::Points',
  -xlabel     => 'X Label',
  -ylabel     => 'Y Label',
  -pointline  => 1,
  -background => 'snow',
  -markersize => 6,
  -linewidth  => 2,
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
  [ 1,     2,     5,     6,     3,     1.5,   1,     3,     4 ],
  [ 4,     2,     5,     2,     3,     5.5,   7,     9,     4 ],
  [ 1,     2,     52,    6,     3,     17.5,  1,     43,    10 ]
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
