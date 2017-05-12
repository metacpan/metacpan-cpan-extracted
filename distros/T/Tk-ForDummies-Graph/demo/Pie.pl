#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::ForDummies::Graph::Pie;
my $mw = new MainWindow( -title => 'Tk::ForDummies::Graph::Pie example', );

my $GraphDummies = $mw->Pie(
  -title      => 'There are currently 231 CPAN mirrors around the World.',
  -background => 'white',
  -linewidth  => 2,
)->pack(qw / -fill both -expand 1 /);

my @data = ( [ 'Europe', 'Asia', 'Africa', 'Oceania', 'Americas' ], [ 119, 33, 3, 6, 67 ], );

$GraphDummies->plot( \@data );

MainLoop();
