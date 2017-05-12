#!/usr/bin/perl
#
# Use PlotPTk to make plots.

use Tk;
use Tk::LineGraph;
use Tk::LineGraphDataset;
use strict;

my $mw = MainWindow->new;

my $cp = $mw->LineGraph
  (
   -height => 600,
   -width  => 800,
   background => 'snow1',

     )->grid;


#OK, make some lines with different limits so we can scale 
my @yArray1 = (-100, 200);
my @xArray1 = (0,600);
my $ds1 = LineGraphDataset->new(-yData=>\@yArray1, -xData=>\@xArray1,               -name=>"setOne");
$cp->addDatasets(-dataset=>$ds1);

my @yArray2 = (50,400);
my @xArray2 = (0,600);
my $ds2 = LineGraphDataset->new(-yData=>\@yArray2, -xData=>\@xArray2,               -name=>"setTwo");
$cp->addDatasets(-dataset=>$ds2);

my @yArray3 = (30,30);
my @xArray3 = (0,600);
my $ds3 = LineGraphDataset->new(-yData=>\@yArray3, -xData=>\@xArray3,               -name=>"setThr");
$cp->addDatasets(-dataset=>$ds3);

my @yArray4 = (100,100);
my $ds4 = LineGraphDataset->new(-yData=>\@yArray4, -xData=>\@xArray1,    -name=>"setFour");
$cp->addDatasets(-dataset=>$ds4);

my @yArray5 = (150,150);
my $ds5 = LineGraphDataset->new(-yData=>\@yArray5, -xData=>\@xArray1,   -name=>"setFive");
$cp->addDatasets(-dataset=>$ds5);


my @yArray6 = (0,1700);
my $ds6 = LineGraphDataset->new(-yData=>\@yArray6, -xData=>\@xArray1,     -name=>"setSix");
$cp->addDatasets(-dataset=>$ds6);


my @yArray7 = (0,10, 177, 300, 1000, 1400, 1500, 1600, 1700);
my @xArray7 = (0, 50, 70, 99,  200,   300,  400,  500,  555);
my $ds7 = LineGraphDataset->new(-yData=>\@yArray7, -xData=>\@xArray7,     -name=>"setSeven");
$cp->addDatasets(-dataset=>$ds7);

my @yArray8 = (0,10, 77, 300, 1000, 1400, 1500, 1600, 1700);
my @xArray8 = (0, 50,70, 99,  200,   300,  400,  500,  555);
my $ds8 = LineGraphDataset->new(-yData=>\@yArray8, -xData=>\@xArray8, -yAxis=>"Y1",   -name=>"setSeven8");
$cp->addDatasets(-dataset=>$ds8);

$cp->plot();


MainLoop;
