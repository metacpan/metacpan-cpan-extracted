#!/usr/bin/perl
#==================================================================
# $Author    : Djibril Ousmanou      $
# $Copyright : 2011                  $
# $Update    : 01/01/2011 00:00:00   $
# $AIM       : Venn diagram example  $
#==================================================================
use warnings;
use Carp;
use strict;

use Venn::Chart;

# Create the Venn::Chart constructor
my $venn_chart = Venn::Chart->new( 400, 400 ) or croak("error : $!");

# Set a title and a legend for our chart
$venn_chart->set_options( -title => 'Venn diagram' );
$venn_chart->set_legends( 'Team 1', 'Team 2', 'Team 3' );

# 3 lists for the Venn diagram
my @team1 = qw/abel edward momo albert jack julien chris/;
my @team2 = qw/edward isabel antonio delta albert kevin jake/;
my @team3 = qw/gerald jake kevin lucia john edward/;

# Create a diagram with gd object
my $gd_venn = $venn_chart->plot( \@team1, \@team2, \@team3 );

# Create a Venn diagram image in png, gif and jpeg format
open my $fh_venn, '>', 'VennChart.png' or croak("Unable to create png file\n");
binmode $fh_venn;
print {$fh_venn} $gd_venn->png;
close $fh_venn or croak('Unable to close file');

# Create an histogram image of Venn diagram (png, gif and jpeg format)
my $gd_histogram = $venn_chart->plot_histogram;
open my $fh_histo, '>', 'VennHistogram.png' or croak("Unable to create png file\n");
binmode $fh_histo;
print {$fh_histo} $gd_histogram->png;
close $fh_histo or croak('Unable to close file');

# Get data list for each intersection or unique region between the 3 lists
my @ref_lists   = $venn_chart->get_list_regions();
my $list_number = 1;
foreach my $ref_region (@ref_lists) {
  print "List $list_number : @{ $ref_region }\n";
  $list_number++;
}
