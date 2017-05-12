#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Chart::Boxplots;

my $mw = MainWindow->new(
  -title      => 'Tk::Chart::Boxplots',
  -background => 'white',
);

my $chart = $mw->Boxplots(
  -title      => 'Tk::Chart::Boxplots',
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
my @legends = ( 'boxplot 1', 'boxplot 2' );
$chart->set_legend(
  -title => 'Title legend',
  -data  => \@legends,
);

# Add help identification
$chart->set_balloon();

# Create the graph
$chart->plot( \@data );

my $ref_array_information = $chart->boxplot_information();

# Print information of boxplot @{$data[2][3]} (2th sample, 4th data )
print "Boxplot @{$data[2][3]} (2th sample, 4th data )\n";
print "Outliers : @{$ref_array_information->[1][3]->{outliers}}\n";
print '25th percentile (Q1) : ', $ref_array_information->[1][3]->{Q1},                   "\n";
print '75th percentile (Q3) :',  $ref_array_information->[1][3]->{Q3},                   "\n";
print 'Smallest non-outlier : ', $ref_array_information->[1][3]->{smallest_non_outlier}, "\n";
print 'Largest non-outlier :',   $ref_array_information->[1][3]->{largest_non_outlier},  "\n";
print 'Median : ',               $ref_array_information->[1][3]->{median},               "\n";
print 'Mean : ',                 $ref_array_information->[1][3]->{mean},                 "\n";

my $one     = [ 210 .. 275 ];
my $two     = [ 180, 190, 200, 220, 235, 245 ];
my $three   = [ 40, 140 .. 150, 160 .. 180, 250 ];
my $four    = [ 100 .. 125, 136 .. 140 ];
my $five    = [ 10 .. 50, 100, 180 ];
my @new_data = ( $one, $two, $three, $four, $five );

$chart->add_data( \@new_data, 'boxplot 3' );

MainLoop();
