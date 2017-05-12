#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::ForDummies::Graph::Bars;

my $mw = new MainWindow(
  -title      => 'Tk::ForDummies::Graph::Bars - overwrite',
  -background => 'white',
);

my $GraphDummies = $mw->Bars(
  -title      => 'Tk::ForDummies::Graph::Bars - overwrite',
  -xlabel     => 'X Label',
  -ylabel     => 'Y Label',
  -overwrite  => 1,
  -showvalues => 1,
  -background => 'snow',
  -longticks  => 1,
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
  [ 4,     0,     16,    2,     3,     5.5,   7,     5,     02 ],
  [ 1,     2,     4,     6,     3,     17.5,  1,     20,    10 ]
);

# Add a legend to the graph
my @Legends = ( 'legend 1', 'legend 2', );
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
