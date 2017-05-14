#!/usr/local/bin/perl

use strict;
use Tk;
use Tk::Canvas;
my $mw=MainWindow->new();


my $c=$mw->Canvas(-width=>481,-height=>357)->pack;


# Masyania
$c->configure(-background=>'lightblue');
my $cnv_Polygon_1 = $c->create('polygon',388,135,397,134,398.50,154.50,390,154,-fill,'wheat2',-outline,'Black');
my $cnv_Splash_2 = $c->create('polygon',363,100,428,99,462.50,127.50,391.25,143.75,326,132,-fill,'wheat2',-outline,'Black',-smooth,1);
my $cnv_Splash_3 = $c->create('polygon',370,147,424.50,144,445,222,356,229,-fill,'wheat2',-outline,'Black',-smooth,1);
my $cnv_Oval_4 = $c->create('oval',376,99,394,113,-fill,'White',-outline,'Black');
my $cnv_Oval_5 = $c->create('oval',395,100,413,114,-fill,'White',-outline,'Black');
my $cnv_Curve_6 = $c->create('line',310,80,344,69,355,109,-smooth,1);
my $cnv_Oval_7 = $c->create('oval',381,100,388,111,-fill,'Blue');
my $cnv_Oval_8 = $c->create('oval',401,101,408,112,-fill,'Blue');
my $cnv_Curve_9 = $c->create('line',320,59,351,65,363,105,-smooth,1);
my $cnv_Curve_10 = $c->create('line',434,122,394,143,355,125,-arrow,'none',-width,2,-smooth,1);
my $cnv_Curve_11 = $c->create('line',471,58,440,64,428,104,-smooth,1);
my $cnv_Splash_12 = $c->create('polygon',375,150,386.38,149.63,398.75,166.25,411.13,147.88,420.50,146.50,414.63,176.63,435.75,184.75,438,192,396.50,202,363,190,359.50,180,382.25,182.50,-fill,'Red',-outline,'Black',-smooth,1);
my $cnv_Curve_13 = $c->create('line',373,162,342,168,330,208,-smooth,1);
my $cnv_Curve_14 = $c->create('line',471,120,461,162,423,159,-smooth,1);
my $cnv_Splash_15 = $c->create('polygon',392,218,415,211,403.50,273.50,408,350,-fill,'wheat2',-outline,'Black',-smooth,1);
my $cnv_Splash_16 = $c->create('polygon',368,215,400,219,390.50,283.50,393,349,386.50,241,-fill,'wheat2',-outline,'Black',-smooth,1);
my $cnv_Splash_17 = $c->create('polygon',358,198,395.75,213.50,434.50,207,430.75,213.50,431,236,410,226,369.50,222.50,358.25,233.75,-fill,'Blue',-outline,'Black',-smooth,1);
my $cnv_Curve_18 = $c->create('line',256,206,263,219,258,225,-smooth,1);
my $cnv_Line_19 = $c->create('line',255,205,238,214);
my $cnv_Curve_20 = $c->create('line',473,87,442,77,433,105,-smooth,1);
my $cnv_Curve_21 = $c->create('line',386,91.50,383,97,373,95.50,-smooth,1);
my $cnv_Line_22 = $c->create('line',399,92.50,412.50,96.50);
my $cnv_Curve_23 = $c->create('line',154,192,161,205,156,211,-smooth,1);
my $cnv_Line_24 = $c->create('line',154,192,137,201);
my $cnv_Polygon_25 = $c->create('polygon',202,142,211,141,212.50,161.50,204,161,-fill,'wheat2',-outline,'Black');
my $cnv_Splash_26 = $c->create('polygon',177,107,242,106,252.50,147.50,160,147,-fill,'wheat2',-outline,'Black',-smooth,1);
my $cnv_Splash_27 = $c->create('polygon',184,154,238.50,151,234,242,179,240,-fill,'wheat2',-outline,'Black',-smooth,1);
my $cnv_Oval_28 = $c->create('oval',182,110,200,124,-fill,'White',-outline,'Black');
my $cnv_Oval_29 = $c->create('oval',209,109,227,123,-fill,'White',-outline,'Black');
my $cnv_Curve_30 = $c->create('line',153,79,187,68,198,108,-smooth,1);
my $cnv_Oval_31 = $c->create('oval',187,111,194,122,-fill,'Blue');
my $cnv_Oval_32 = $c->create('oval',215,110,222,121,-fill,'Blue');
my $cnv_Curve_33 = $c->create('line',162,61,193,67,205,107,-smooth,1);
my $cnv_Curve_34 = $c->create('line',227,132,208,150,180,132,-arrow,'none',-width,2,-smooth,1);
my $cnv_Curve_35 = $c->create('line',255,61,224,67,212,107,-smooth,1);
my $cnv_Splash_36 = $c->create('polygon',189,157,200.38,156.63,205.75,182.25,220.13,156.88,232.50,155.50,238.75,195.75,235,234,205.50,221,179,230,180.50,197,-fill,'Red',-outline,'Black',-smooth,1);
my $cnv_Curve_37 = $c->create('line',189,165,158,171,146,211,-smooth,1);
my $cnv_Curve_38 = $c->create('line',248,221,272,171,234,168,-smooth,1);
my $cnv_Splash_39 = $c->create('polygon',213,233,225,228,221.50,291.50,224,357,-fill,'wheat2',-outline,'Black',-smooth,1);
my $cnv_Splash_40 = $c->create('polygon',189,233,201,228,197.50,291.50,200,357,-fill,'wheat2',-outline,'Black',-smooth,1);
my $cnv_Splash_41 = $c->create('polygon',180.55,209.20,206.97,227.80,234.10,220,231.47,227.80,231.65,254.80,216.95,242.80,188.60,238.60,180.72,252.10,-fill,'Blue',-outline,'Black',-smooth,1);
my $cnv_Curve_42 = $c->create('line',338,190,345,203,340,209,-smooth,1);
my $cnv_Line_43 = $c->create('line',338,190,321,199);
my $cnv_Curve_44 = $c->create('line',461,120,468,133,463,139,-smooth,1);
my $cnv_Line_45 = $c->create('line',481,127,464,136);

MainLoop;
