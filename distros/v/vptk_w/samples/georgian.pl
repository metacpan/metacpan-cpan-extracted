#!/usr/local/bin/perl

use strict;
use Tk;
use Tk::Canvas;
my $mw=MainWindow->new();


my $c=$mw->Canvas(-width=>356.50,-height=>244)->pack;


$c->configure(-background=>'gray');
my $cnv_Rectangle_1 = $c->create('rectangle',314.00,108.00,329.00,117.00,-fill,'White',-outline,'gray75',-tags=>['cnv_Rectangle_1','cnv_obj']);
my $cnv_Splash_2 = $c->create('polygon',187.00,67.00,224.00,68.00,217.50,101.00,198.00,103.00,-fill,'wheat2',-outline,'Black',-smooth,1.00,-tags=>['cnv_Splash_2','cnv_obj']);
my $cnv_Polygon_3 = $c->create('polygon',182.00,89.00,207.00,90.50,230.00,86.00,216.50,95.00,198.00,95.00,-tags=>['cnv_Polygon_3','cnv_obj']);
my $cnv_Splash_4 = $c->create('polygon',225.50,41.50,224.50,77.50,204.00,71.50,188.00,80.00,194.50,43.00,-smooth,1.00,-tags=>['cnv_Splash_4','cnv_obj']);
my $cnv_Polygon_5 = $c->create('polygon',161.00,107.00,210.75,102.00,249.50,107.00,246.75,153.00,232.00,234.00,173.00,229.00,169.00,153.50,-tags=>['cnv_Polygon_5','cnv_obj']);
my $cnv_Polygon_6 = $c->create('polygon',218.20,77.20,207.10,83.50,191.80,77.80,199.00,83.20,213.70,83.80,-tags=>['cnv_Polygon_6','cnv_obj']);
my $cnv_Line_7 = $c->create('line',176.00,119.00,176.00,133.00,-arrow,'none',-fill,'White',-width,3.00,-tags=>['cnv_Line_7','cnv_obj']);
my $cnv_Line_8 = $c->create('line',182.00,119.00,182.00,133.00,-arrow,'none',-fill,'White',-width,3.00,-tags=>['cnv_Line_8','cnv_obj']);
my $cnv_Line_9 = $c->create('line',188.00,120.00,188.00,134.00,-arrow,'none',-fill,'White',-width,3.00,-tags=>['cnv_Line_9','cnv_obj']);
my $cnv_Polygon_10 = $c->create('polygon',208.00,101.00,218.00,176.00,189.00,171.00,-fill,'gray75',-tags=>['cnv_Polygon_10','cnv_obj']);
my $cnv_Splash_11 = $c->create('polygon',218.48,195.80,193.73,156.20,227.27,183.15,-fill,'Brown',-smooth,1.00,-tags=>['cnv_Splash_11','cnv_obj']);
my $cnv_Polygon_12 = $c->create('polygon',223.00,181.00,274.00,244.00,217.00,191.00,-fill,'White',-tags=>['cnv_Polygon_12','cnv_obj']);
my $cnv_Line_13 = $c->create('line',226.00,177.00,214.00,197.00,-arrow,'none',-fill,'Brown',-width,2.00,-tags=>['cnv_Line_13','cnv_obj']);
my $cnv_Splash_14 = $c->create('polygon',300.00,74.00,337.00,75.00,330.50,108.00,311.00,110.00,-fill,'wheat2',-outline,'Black',-smooth,1.00,-tags=>['cnv_Splash_14','cnv_obj']);
my $cnv_Polygon_15 = $c->create('polygon',330.20,85.20,319.10,91.50,303.80,85.80,311.00,91.20,325.70,91.80,-tags=>['cnv_Polygon_15','cnv_obj']);
my $cnv_Splash_16 = $c->create('polygon',299.00,50.00,342.00,49.50,356.00,90.00,320.00,77.00,288.00,88.00,-fill,'DarkViolet',-smooth,1.00,-tags=>['cnv_Splash_16','cnv_obj']);
my $cnv_Polygon_17 = $c->create('polygon',311.50,100.00,326.00,100.50,319.00,105.00,-fill,'Brown',-tags=>['cnv_Polygon_17','cnv_obj']);
my $cnv_Splash_18 = $c->create('polygon',287.00,114.00,356.50,117.00,354.00,203.00,286.00,198.00,-fill,'White',-outline,'gray75',-smooth,1.00,-tags=>['cnv_Splash_18','cnv_obj']);
my $cnv_Line_19 = $c->create('line',321.00,51.00,316.00,75.00,-arrow,'none',-width,3.00,-tags=>['cnv_Line_19','cnv_obj']);
my $cnv_Line_20 = $c->create('line',225.00,119.00,225.00,133.00,-arrow,'none',-fill,'White',-width,3.00,-tags=>['cnv_Line_20','cnv_obj']);
my $cnv_Line_21 = $c->create('line',231.00,117.00,231.00,131.00,-arrow,'none',-fill,'White',-width,3.00,-tags=>['cnv_Line_21','cnv_obj']);
my $cnv_Line_22 = $c->create('line',237.00,116.00,237.00,130.00,-arrow,'none',-fill,'White',-width,3.00,-tags=>['cnv_Line_22','cnv_obj']);

MainLoop;
