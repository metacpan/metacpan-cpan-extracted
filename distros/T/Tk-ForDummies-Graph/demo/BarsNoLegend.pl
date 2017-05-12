#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::ForDummies::Graph::Bars;

my $mw = new MainWindow(
  -title      => 'Tk::ForDummies::Graph::Bars No legend',
  -background => 'white',
);

my $GraphDummies = $mw->Bars(
  -title      => 'Tk::ForDummies::Graph::Bars - no legend',
  -xlabel     => 'X Label',
  -background => 'snow',
  -ylabel     => 'Y Label',
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
  [ 4,     0,     16,    2,     3,     5.5,   7,     5,     02 ],
  [ 1,     2,     4,     6,     3,     17.5,  1,     20,    10 ]
);

# Create the graph
$GraphDummies->plot( \@data );
MainLoop();
