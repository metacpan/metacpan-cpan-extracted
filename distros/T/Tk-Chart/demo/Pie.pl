#!/usr/bin/perl
use strict;
use warnings;
use Tk;

use Tk::Chart::Pie;
my $mw = MainWindow->new( -title => 'Tk::Chart::Pie example', );

my $chart = $mw->Pie(
  -title      => 'There are currently 231 CPAN mirrors around the World (20/09/2010 18:50:57).',
  -background => 'white',
  -linewidth  => 2,
)->pack(qw / -fill both -expand 1 /);

my @data = ( [ 'Europe', 'Asia', 'Africa', 'Oceania', 'Americas' ], [ 119, 33, 3, 6, 67 ], );

$chart->plot( \@data );

MainLoop();
