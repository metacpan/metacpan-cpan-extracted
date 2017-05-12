#!/usr/bin/perl
use strict;
use warnings;

use Tk;
use Tk::ForDummies::Graph::Mixed;

my $mw = new MainWindow(
  -title      => 'Background gradient color - Tk::ForDummies::Graph::Mixed',
  -background => 'white',
);

my @types = ( 'areas', 'bars', 'lines', 'points', 'bars', 'dashlines' );
my $GraphDummies = $mw->Mixed(
  -title     => 'Background gradient color - Mixed',
  -xlabel    => 'X Label',
  -ylabel    => 'Y Label',
  -linewidth => 2,
  -typemixed => \@types,
  -markers   => [ 3, 5, 6 ],
  -longticks => 1,
)->pack(qw / -fill both -expand 1 /);

# enabled background gradient color
$GraphDummies->enabled_gradientcolor();

# set background gradient color (default options)
$GraphDummies->set_gradientcolor();

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
  [ 90,    29,    25,    6,     -20,   1,     1,     3,     4 ],
  [ 15,    10,    5,     2,     3,     5,     7,     9,     12 ],
  [ 1,     2,     12,    6,     3,     5,     1,     23,    5 ],
  [ 15,    12,    24,    33,    19,    8,     6,     15,    21 ],
  [ 15,    2,     52,    6,     3,     17.5,  1,     43,    10 ],
  [ 30,    2,     5,     6,     3,     1.5,   1,     3,     4 ],
  [ 24,    12,    35,    20,    13,    31.5,  41,    6,     25 ],

);

# Add a legend to the graph
my @Legends = @types;
$GraphDummies->set_legend(
  -title       => 'Title legend',
  -data        => [ 'legend 1', 'legend 2', 'legend 3', 'legend 4', 'legend 5', 'legend 6', 'legend 7', ],
  -titlecolors => 'blue',
);

# Add help identification
$GraphDummies->set_balloon();

# Create the graph
$GraphDummies->plot( \@data );

# background order wanted
$GraphDummies->display_order( [qw/ areas bars lines dashlines points /] );

MainLoop();

