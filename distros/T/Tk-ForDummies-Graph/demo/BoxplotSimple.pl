#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::ForDummies::Graph::Boxplots;

my $mw = new MainWindow(
  -title      => 'Tk::ForDummies::Graph::Boxplots',
  -background => 'white',
);

my $GraphDummies = $mw->Boxplots(
  -title      => 'Tk::ForDummies::Graph::Boxplots',
  -xlabel     => 'X Label',
  -ylabel     => 'Y Label',
  -background => 'snow',
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th' ],
  [ [ 100 .. 125, 136 .. 140 ],
    [ 22 .. 89 ],
    [ 12, 54, 88, 10 ],
    [ 12,      11, 23, 14 .. 98, 45 ],
    [ 0 .. 55, 11, 12 ]
  ],
  [ [ -25 .. -5, 1 .. 15 ],
    [ -45, 25 .. 45, 100 ],
    [ 70,  42 .. 125 ],
    [ 100, 30, 50 .. 78, 88, ],
    [ 180 .. 250 ]
  ],

  #...
);

# Add a legend to the graph
my @Legends = ( 'boxplot 1', 'boxplot 2' );
$GraphDummies->set_legend(
  -title => 'Title legend',
  -data  => \@Legends,
);

# Add help identification
$GraphDummies->set_balloon();

# Create the graph
$GraphDummies->plot( \@data );

my $ArrayRefInformation = $GraphDummies->boxplot_information();

# Print information of boxplot @{$data[2][3]} (2th sample, 4th data )
print "Boxplot @{$data[2][3]} (2th sample, 4th data )\n";
print "Outliers : @{$ArrayRefInformation->[1][3]->{outliers}}\n";
print '25th percentile (Q1) : ', $ArrayRefInformation->[1][3]->{Q1},                   "\n";
print '75th percentile (Q3) :',  $ArrayRefInformation->[1][3]->{Q3},                   "\n";
print 'Smallest non-outlier : ', $ArrayRefInformation->[1][3]->{smallest_non_outlier}, "\n";
print 'Largest non-outlier :',   $ArrayRefInformation->[1][3]->{largest_non_outlier},  "\n";
print 'Median : ',               $ArrayRefInformation->[1][3]->{median},               "\n";
print 'Mean : ',                 $ArrayRefInformation->[1][3]->{mean},                 "\n";

my $one     = [ 210 .. 275 ];
my $two     = [ 180, 190, 200, 220, 235, 245 ];
my $three   = [ 40, 140 .. 150, 160 .. 180, 250 ];
my $four    = [ 100 .. 125, 136 .. 140 ];
my $five    = [ 10 .. 50, 100, 180 ];
my @NewData = ( $one, $two, $three, $four, $five );

$GraphDummies->add_data( \@NewData, 'boxplot 3' );

MainLoop();
