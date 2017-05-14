#!/usr/local/bin/perl

use strict;
use Tk;
use Tk::Canvas;
my $mw=MainWindow->new();


my $c=$mw->Canvas(-width=>402.50,-height=>366.50)->pack;


# Sea
$c->configure(-background=>'lightblue');
my $cnv_Oval_1 = $c->create('oval',145.26,66.56,150.18,73.94,-fill,'gray50',-tags=>['cnv_Oval_1','cnv_obj']);
my $cnv_Oval_2 = $c->create('oval',138.76,66.56,143.68,73.94,-fill,'gray50',-tags=>['cnv_Oval_2','cnv_obj']);
my $cnv_Oval_3 = $c->create('oval',143.10,73.23,153.97,82.80,-fill,'Magenta',-outline,'Magenta',-tags=>['cnv_Oval_3','cnv_obj']);
my $cnv_Circle_4 = $c->create('oval',275.60,-29.40,304.40,-0.60,-fill,'Yellow',-outline,'Yellow',-tags=>['cnv_Circle_4','cnv_obj']);
my $cnv_Splash_5 = $c->create('polygon',208.00,277.00,228.00,271.50,233.00,307.00,211.00,308.00,-fill,'red4',-smooth,1.00,-tags=>['cnv_Splash_5','cnv_obj']);
my $cnv_Splash_6 = $c->create('polygon',231.00,275.00,251.00,269.50,256.00,305.00,234.00,306.00,-fill,'red4',-smooth,1.00,-tags=>['cnv_Splash_6','cnv_obj']);
my $cnv_Oval_7 = $c->create('oval',136.21,48.87,142.80,64.87,-fill,'White',-outline,'White',-tags=>['cnv_Oval_7','cnv_obj']);
my $cnv_Polygon_8 = $c->create('polygon',327.83,160.33,341.83,174.67,346.50,202.67,330.67,175.83,322.21,165.96,306.08,163.08,297.50,159.33,306.83,158.50,-fill,'DarkGreen',-tags=>['cnv_Polygon_8','cnv_obj']);
my $cnv_Curve_9 = $c->create('line',23.50,282.99,63.60,267.59,94.70,293.20,139.23,267.19,182.76,289.19,-arrow,'none',-fill,'Blue',-width,2.00,-smooth,1.00,-splinesteps,8.00,-tags=>['cnv_Curve_9','cnv_obj']);
my $cnv_Polygon_10 = $c->create('polygon',271.17,163.67,260.50,180.33,269.17,200.00,268.67,178.83,277.79,166.96,293.58,164.08,297.50,158.00,284.17,159.83,-fill,'DarkGreen',-tags=>['cnv_Polygon_10','cnv_obj']);
my $cnv_Curve_11 = $c->create('line',-39.50,230.99,0.60,215.59,31.70,241.20,76.23,215.19,119.76,237.19,-arrow,'none',-fill,'Blue',-width,2.00,-smooth,1.00,-splinesteps,8.00,-tags=>['cnv_Curve_11','cnv_obj']);
my $cnv_Polygon_12 = $c->create('polygon',284.17,184.00,279.17,203.33,287.83,223.00,287.33,201.83,292.12,187.62,293.25,170.75,296.50,161.33,284.83,167.83,-fill,'DarkGreen',-tags=>['cnv_Polygon_12','cnv_obj']);
my $cnv_Curve_13 = $c->create('line',12.50,184.99,52.60,169.59,83.70,195.20,128.23,169.19,171.76,191.19,-arrow,'none',-fill,'Blue',-width,2.00,-smooth,1.00,-splinesteps,8.00,-tags=>['cnv_Curve_13','cnv_obj']);
my $cnv_Polygon_14 = $c->create('polygon',324.50,173.67,332.50,196.67,329.17,212.00,323.33,194.83,314.87,179.29,301.75,168.08,299.17,161.33,309.17,166.83,-fill,'DarkGreen',-tags=>['cnv_Polygon_14','cnv_obj']);
my $cnv_Line_15 = $c->create('line',167.33,247.50,176.33,248.00,-tags=>['cnv_Line_15','cnv_obj']);
my $cnv_Splash_16 = $c->create('polygon',194.92,194.52,239.16,193.44,233.44,224.44,200.28,222.52,-fill,'red4',-smooth,1.00,-tags=>['cnv_Splash_16','cnv_obj']);
my $cnv_Line_17 = $c->create('line',168.00,251.00,178.00,249.00,-tags=>['cnv_Line_17','cnv_obj']);
my $cnv_Line_18 = $c->create('line',263.00,245.00,273.00,244.50,-tags=>['cnv_Line_18','cnv_obj']);
my $cnv_Line_19 = $c->create('line',263.33,243.67,274.33,243.00,-tags=>['cnv_Line_19','cnv_obj']);
my $cnv_PolyLine_20 = $c->create('line',-84.83,77.18,-33.19,73.79,101.53,80.37,-arrow,'none',-fill,'Blue',-width,2.00,-tags=>['cnv_PolyLine_20','cnv_obj']);
my $cnv_Oval_21 = $c->create('oval',203.00,188.00,212.00,203.00,-fill,'red4',-width,3.00,-outline,'red4',-tags=>['cnv_Oval_21','cnv_obj']);
my $cnv_PolyLine_22 = $c->create('line',298.00,158.50,297.00,206.00,315.50,271.50,307.00,328.00,-arrow,'none',-fill,'red4',-width,5.00,-tags=>['cnv_PolyLine_22','cnv_obj']);
my $cnv_Oval_23 = $c->create('oval',218.00,187.00,227.00,202.00,-fill,'red4',-width,3.00,-outline,'red4',-tags=>['cnv_Oval_23','cnv_obj']);
my $cnv_Curve_24 = $c->create('line',19.50,134.99,59.60,119.59,90.70,145.20,135.23,119.19,178.76,141.19,-arrow,'none',-fill,'Blue',-width,2.00,-smooth,1.00,-splinesteps,8.00,-tags=>['cnv_Curve_24','cnv_obj']);
my $cnv_PolyLine_25 = $c->create('line',164.17,81.18,215.81,77.79,350.53,84.37,-arrow,'none',-fill,'Blue',-width,2.00,-tags=>['cnv_PolyLine_25','cnv_obj']);
my $cnv_Curve_26 = $c->create('line',241.35,102.09,269.42,91.32,291.19,109.24,322.36,91.04,352.83,106.43,-arrow,'none',-fill,'Blue',-width,2.00,-splinesteps,8.00,-smooth,1.00,-tags=>['cnv_Curve_26','cnv_obj']);
my $cnv_Curve_27 = $c->create('line',-65.65,110.09,-37.58,99.32,-15.81,117.24,15.36,99.04,45.83,114.43,-arrow,'none',-fill,'Blue',-width,2.00,-splinesteps,8.00,-smooth,1.00,-tags=>['cnv_Curve_27','cnv_obj']);
my $cnv_Splash_28 = $c->create('polygon',194.00,216.67,248.33,219.50,252.33,284.00,193.67,280.00,-fill,'red4',-smooth,1.00,-tags=>['cnv_Splash_28','cnv_obj']);
my $cnv_Polygon_29 = $c->create('polygon',36.23,83.45,176.99,87.60,147.72,127.07,70.36,123.04,-fill,'red4',-tags=>['cnv_Polygon_29','cnv_obj']);
my $cnv_Splash_30 = $c->create('polygon',169.33,241.67,200.00,222.50,204.00,241.00,180.00,256.33,-fill,'red4',-smooth,1.00,-tags=>['cnv_Splash_30','cnv_obj']);
my $cnv_Curve_31 = $c->create('line',153.50,124.99,193.60,109.59,224.70,135.20,269.23,109.19,312.76,131.19,-arrow,'none',-fill,'Blue',-width,2.00,-smooth,1.00,-splinesteps,8.00,-tags=>['cnv_Curve_31','cnv_obj']);
my $cnv_Line_32 = $c->create('line',166.00,244.33,176.00,246.33,-tags=>['cnv_Line_32','cnv_obj']);
my $cnv_Splash_33 = $c->create('polygon',270.50,232.83,240.50,219.00,236.50,237.50,263.83,250.17,-fill,'red4',-smooth,1.00,-tags=>['cnv_Splash_33','cnv_obj']);
my $cnv_Line_34 = $c->create('line',171.17,254.17,178.17,249.67,-tags=>['cnv_Line_34','cnv_obj']);
my $cnv_Curve_35 = $c->create('line',-52.50,329.00,23.62,318.00,106.56,340.50,168.25,343.25,204.25,305.75,283.50,306.50,358.50,366.50,-arrow,'none',-width,2.00,-smooth,1.00,-tags=>['cnv_Curve_35','cnv_obj']);
my $cnv_Line_36 = $c->create('line',264.00,242.00,274.00,240.00,-tags=>['cnv_Line_36','cnv_obj']);
my $cnv_Line_37 = $c->create('line',260.17,245.67,270.17,247.67,-tags=>['cnv_Line_37','cnv_obj']);
my $cnv_Polygon_38 = $c->create('polygon',335.50,146.33,381.50,177.00,402.50,213.00,366.67,179.83,332.75,159.25,297.50,158.00,306.50,152.50,-fill,'DarkGreen',-tags=>['cnv_Polygon_38','cnv_obj']);
my $cnv_Polygon_39 = $c->create('polygon',257.50,144.50,224.50,172.50,222.50,197.50,240.58,171.25,262.00,159.00,297.50,157.50,286.50,147.50,-fill,'DarkGreen',-tags=>['cnv_Polygon_39','cnv_obj']);
my $cnv_Oval_40 = $c->create('oval',135.10,72.73,145.97,82.80,-fill,'Magenta',-outline,'Magenta',-tags=>['cnv_Oval_40','cnv_obj']);
my $cnv_Oval_41 = $c->create('oval',129.27,63.52,159.34,84.52,-outline,'White',-width,4.00,-tags=>['cnv_Oval_41','cnv_obj']);
my $cnv_Line_42 = $c->create('line',118.65,-12.93,112.69,85.54,-arrow,'none',-fill,'Red',-width,2.00,-tags=>['cnv_Line_42','cnv_obj']);
my $cnv_Polygon_43 = $c->create('polygon',122.99,-6.01,171.25,-3.88,153.81,-0.29,159.37,9.31,124.44,6.40,-fill,'DarkGreen',-tags=>['cnv_Polygon_43','cnv_obj']);
my $cnv_Oval_44 = $c->create('oval',146.71,48.87,153.30,65.87,-fill,'White',-outline,'White',-tags=>['cnv_Oval_44','cnv_obj']);

MainLoop;
