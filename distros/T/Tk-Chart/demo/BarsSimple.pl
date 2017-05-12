#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Chart::Bars;

my $mw = MainWindow->new(
  -title      => 'Tk::Chart::Bars',
  -background => 'white',
);
my $chart = $mw->Bars(
  -title      => 'Tk::Chart::Bars',
  -xlabel     => 'X Label',
  -ylabel     => 'Y Label',
  -background => 'snow',
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
  [ 1,     2,     5,     6,     3,     1,     1,     3,     4 ],
  [ 4,     2,     5,     2,     3,     5,     7,     9,     12 ],
  [ 1,     2,     12,    6,     3,     5,     1,     23,    5 ]
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
