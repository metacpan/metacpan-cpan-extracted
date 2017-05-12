#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::ForDummies::Graph::Lines;

my $mw = new MainWindow(
  -title      => 'Tk::ForDummies::Graph::Lines',
  -background => 'white',
);

my $GraphDummies = $mw->Lines(
  -background   => 'snow',
  -title        => 'Tk::ForDummies::Graph::Lines example - negative values',
  -xlabel       => 'X Label',
  -ylabel       => 'Y Label',
  -zeroaxisonly => 1,
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
  [ 4,     -4,    -16,   -2,    -3,    -5.5,  -7,    -5,    -2 ],
  [ -1,    -2,    -4,    -6,    -3,    -17.5, -1,    -20,   -10 ]
);

# Create the graph
$GraphDummies->plot( \@data );
MainLoop();
