#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::ForDummies::Graph::Bars;

my $mw = new MainWindow(
  -title      => 'Tk::ForDummies::Graph::Bars - no spacingbar',
  -background => 'white',
);
my $GraphDummies = $mw->Bars(
  -title      => 'Tk::ForDummies::Graph::Bars - no spacingbar',
  -xlabel     => 'X Label',
  -ylabel     => 'Y Label',
  -background => 'snow',
  -spacingbar => 0,
  -showvalues => 1,
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
  [ 1,     2,     5,     6,     3,     1.5,   1,     3,     4 ],
  [ 4,     2,     5,     2,     3,     5.5,   7,     9,     4 ],
  [ 1,     2,     52,    6,     3,     17.5,  1,     43,    10 ]
);

# Add a legend to the graph
my @Legends = ( 'legend 1', 'legend 2', 'legend 3' );
$GraphDummies->set_legend(
  -title       => 'Title legend',
  -data        => \@Legends,
  -titlecolors => 'blue',
);

# Add help identification
$GraphDummies->set_balloon();

# Create the graph
$GraphDummies->plot( \@data );

MainLoop();
