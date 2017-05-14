#!/usr/local/bin/perl

use strict;
use Tk;
use Tk::Canvas;
my $mw=MainWindow->new();


my $c=$mw->Canvas(-width=>490,-height=>170)->pack;


# Helicopter (c) Felix Liberman 
$c->configure(-background=>'lightblue');
my $cnv_Chord_11 = $c->create('arc',274.00,57.00,355.00,165.00,-start,356.00,-fill,'Blue',-extent,82.00,-style,'chord',-tags=>['cnv_Chord_11','cnv_obj']);
my $cnv_Pie_12 = $c->create('arc',247.00,58.00,396.00,170.00,-start,90.00,-fill,'Cyan',-extent,90.00,-tags=>['cnv_Pie_12','cnv_obj']);
my $cnv_Polygon_13 = $c->create('polygon',107.00,114.00,322.00,114.00,322.00,148.00,-fill,'Cyan',-outline,'Black',-tags=>['cnv_Polygon_13','cnv_obj']);
my $cnv_Splash_14 = $c->create('polygon',255.00,35.00,388.50,71.00,490.00,51.00,158.00,55.00,-smooth,1.00,-tags=>['cnv_Splash_14','cnv_obj']);
my $cnv_Pie_15 = $c->create('arc',288.00,79.00,355.00,148.00,-start,270.00,-fill,'Cyan',-extent,90.00,-tags=>['cnv_Pie_15','cnv_obj']);
my $cnv_Circle_16 = $c->create('oval',311.00,142.00,333.00,164.00,-width,10.00,-tags=>['cnv_Circle_16','cnv_obj']);
my $cnv_Splash_17 = $c->create('polygon',109.00,78.00,108.00,151.00,121.50,125.00,97.00,103.00,-smooth,1.00,-tags=>['cnv_Splash_17','cnv_obj']);

MainLoop;
