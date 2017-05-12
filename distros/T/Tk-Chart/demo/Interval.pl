#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Chart::Lines;

my $mw = MainWindow->new(
  -title      => '-interval, -yminvalue and -ymaxvalue options',
  -background => 'white',
);
$mw->Label(
  -text => "3 charts using Tk::Chart::Bars with short interval data\n"
    . 'data : 29.9, 30, 29.95, 29.99, 29.92, 29.91, 29.97, 30.1',
  -background => 'white',
)->pack(qw / -side top /);

my $chart = $mw->Lines( -title => 'No Interval', )->pack(qw / -side left -fill both -expand 1 /);
my $chart2 = $mw->Lines(
  -title     => 'Using -yminvalue and -ymaxvalue options',
  -yminvalue => 29.5,
  -ymaxvalue => 30.5,
)->pack(qw / -side left -fill both -expand 1/);
my $chart3 = $mw->Lines(
  -title    => 'Using -interval option',
  -interval => 1,
)->pack(qw / -side left -fill both -expand 1/);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th' ],
  [ 29.9,  30,    29.95, 29.99, 29.92, 29.91, 29.97, 30.1 ],

);

foreach my $chart ( $chart, $chart2, $chart3 ) {
  $chart->enabled_gradientcolor();
  $chart->configure(
    -xlabel      => 'X Label',
    -ylabel      => 'Y Label',
    -background  => 'snow',
    -linewidth   => 2,
    -yticknumber => 10,
    -ylongticks  => 1,
    -yvaluecolor => '#700000',
  );

  # Add a legend to the graph
  my @legends = ('data 1');
  $chart->set_legend(
    -title => 'Legend',
    -data  => \@legends,
  );

  # Add help identification
  $chart->set_balloon();

  # Create the graph
  $chart->plot( \@data );
}

MainLoop();
