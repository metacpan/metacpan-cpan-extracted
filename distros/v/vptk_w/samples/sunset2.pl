#!/usr/local/bin/perl

use strict;
use Tk;
use Tk::Canvas;
my $mw=MainWindow->new();


my $c=$mw->Canvas(-width=>631,-height=>307)->pack;


# Sunset (c) by Felix Liberman             
$c->configure(-background=>'gray');
my $cnv_Polygon_1 = $c->create('polygon',-15,169.00,631.00,170.00,613.50,303.50,-9,307.00,-fill,'DarkSeaGreen',-tags=>['cnv_Polygon_1','cnv_obj']);
my $cnv_Circle_2 = $c->create('oval',221.00,96.00,327.00,202.00,-fill,'orange',-outline,'orange',-tags=>['cnv_Circle_2','cnv_obj']);
my $cnv_Splash_3 = $c->create('polygon',275.00,171.00,536.50,170.00,615.00,171.00,603.50,233.00,463.00,268.00,154.50,264.50,15.00,221.00,25.50,169.50,81.75,170.75,-fill,'Blue',-smooth,1.00,-tags=>['cnv_Splash_3','cnv_obj']);
my $cnv_Splash_4 = $c->create('polygon',26.00,173.00,29.00,218.25,66.00,234.50,161.00,258.00,20.00,247.00,10.00,210.50,-fill,'wheat2',-smooth,1.00,-tags=>['cnv_Splash_4','cnv_obj']);
my $cnv_Polygon_5 = $c->create('polygon',550.00,172.00,553.00,248.00,544.00,246.00,543.00,197.00,-fill,'Brown',-tags=>['cnv_Polygon_5','cnv_obj']);
my $cnv_Line_6 = $c->create('line',135.50,219.50,130.50,252.50,-tags=>['cnv_Line_6','cnv_obj']);
my $cnv_Polygon_7 = $c->create('polygon',540.00,211.50,535.50,171.00,545.00,140.00,562.00,176.00,555.50,212.00,-fill,'DarkGreen',-tags=>['cnv_Polygon_7','cnv_obj']);
my $cnv_Line_8 = $c->create('line',139.50,212.00,136.50,247.00,-tags=>['cnv_Line_8','cnv_obj']);
my $cnv_Line_9 = $c->create('line',144.00,221.00,141.50,250.00,-tags=>['cnv_Line_9','cnv_obj']);
my $cnv_Line_10 = $c->create('line',147.00,231.00,144.00,259.00,-tags=>['cnv_Line_10','cnv_obj']);
my $cnv_Line_11 = $c->create('line',157.00,229.00,154.50,258.50,-tags=>['cnv_Line_11','cnv_obj']);
my $cnv_Line_12 = $c->create('line',153.00,230.50,147.50,254.50,-tags=>['cnv_Line_12','cnv_obj']);
my $cnv_Oval_13 = $c->create('oval',132.00,202.00,137.00,222.00,-fill,'Brown',-outline,'Brown',-tags=>['cnv_Oval_13','cnv_obj']);
my $cnv_Oval_14 = $c->create('oval',149.50,214.00,154.50,234.00,-fill,'Brown',-outline,'Brown',-tags=>['cnv_Oval_14','cnv_obj']);
my $cnv_Oval_15 = $c->create('oval',141.50,207.00,146.50,227.00,-fill,'Brown',-outline,'Brown',-tags=>['cnv_Oval_15','cnv_obj']);
my $cnv_Oval_16 = $c->create('oval',137.00,199.50,142.00,219.50,-fill,'Brown',-outline,'Brown',-tags=>['cnv_Oval_16','cnv_obj']);
my $cnv_Polygon_17 = $c->create('polygon',560.00,169.50,563.00,245.50,554.00,243.50,553.00,194.50,-fill,'Brown',-tags=>['cnv_Polygon_17','cnv_obj']);
my $cnv_Oval_18 = $c->create('oval',154.50,219.00,159.50,239.00,-fill,'Brown',-outline,'Brown',-tags=>['cnv_Oval_18','cnv_obj']);
my $cnv_Polygon_19 = $c->create('polygon',581.00,164.00,584.00,240.00,575.00,238.00,574.00,189.00,-fill,'Brown',-tags=>['cnv_Polygon_19','cnv_obj']);
my $cnv_Polygon_20 = $c->create('polygon',552.50,216.00,549.00,176.50,555.50,145.50,575.50,181.50,566.00,212.50,-fill,'DarkGreen',-tags=>['cnv_Polygon_20','cnv_obj']);
my $cnv_Polygon_21 = $c->create('polygon',568.00,204.50,563.50,179.00,580.00,149.00,590.00,184.00,588.50,203.00,-fill,'DarkGreen',-tags=>['cnv_Polygon_21','cnv_obj']);
my $cnv_Line_22 = $c->create('line',162.50,227.50,157.50,260.50,-tags=>['cnv_Line_22','cnv_obj']);
my $cnv_Line_23 = $c->create('line',166.50,220.00,163.50,255.00,-tags=>['cnv_Line_23','cnv_obj']);
my $cnv_Line_24 = $c->create('line',171.00,229.00,168.50,258.00,-tags=>['cnv_Line_24','cnv_obj']);
my $cnv_Polygon_25 = $c->create('polygon',569.00,177.00,572.00,253.00,563.00,251.00,562.00,202.00,-fill,'Brown',-tags=>['cnv_Polygon_25','cnv_obj']);
my $cnv_Line_26 = $c->create('line',175.00,236.00,172.00,264.00,-tags=>['cnv_Line_26','cnv_obj']);
my $cnv_Line_27 = $c->create('line',185.00,234.00,182.50,263.50,-tags=>['cnv_Line_27','cnv_obj']);
my $cnv_Line_28 = $c->create('line',181.00,235.50,175.50,259.50,-tags=>['cnv_Line_28','cnv_obj']);
my $cnv_Oval_29 = $c->create('oval',159.00,210.00,164.00,230.00,-fill,'Brown',-outline,'Brown',-tags=>['cnv_Oval_29','cnv_obj']);
my $cnv_Oval_30 = $c->create('oval',177.50,219.00,182.50,239.00,-fill,'Brown',-outline,'Brown',-tags=>['cnv_Oval_30','cnv_obj']);
my $cnv_Oval_31 = $c->create('oval',169.50,212.00,174.50,232.00,-fill,'Brown',-outline,'Brown',-tags=>['cnv_Oval_31','cnv_obj']);
my $cnv_Oval_32 = $c->create('oval',164.00,207.50,169.00,227.50,-fill,'Brown',-outline,'Brown',-tags=>['cnv_Oval_32','cnv_obj']);
my $cnv_Oval_33 = $c->create('oval',182.50,224.00,187.50,244.00,-fill,'Brown',-outline,'Brown',-tags=>['cnv_Oval_33','cnv_obj']);
my $cnv_Polygon_34 = $c->create('polygon',560.00,218.50,555.50,178.00,567.00,148.00,582.00,183.00,575.50,219.00,-fill,'DarkGreen',-tags=>['cnv_Polygon_34','cnv_obj']);
my $cnv_Splash_35 = $c->create('polygon',302.00,194.20,244.25,175.80,306.50,180.60,295.00,207.00,245.50,204.60,274.38,218.20,280.81,231.00,230.53,238.20,247.39,228.60,267.25,224.60,232.00,203.00,-fill,'orange',-smooth,1.00,-tags=>['cnv_Splash_35','cnv_obj']);
my $cnv_PolyLine_36 = $c->create('line',129.00,181.00,125.00,205.50,116.00,224.00,110.00,251.00,-arrow,'none',-fill,'Brown',-width,3.00,-tags=>['cnv_PolyLine_36','cnv_obj']);
my $cnv_Line_37 = $c->create('line',117.00,192.00,126.00,204.00,-arrow,'none',-fill,'Brown',-width,2.00,-tags=>['cnv_Line_37','cnv_obj']);
my $cnv_Splash_38 = $c->create('polygon',95.00,153.00,157.50,161.00,151.00,196.00,95.00,191.00,-fill,'DarkGreen',-smooth,1.00,-tags=>['cnv_Splash_38','cnv_obj']);

MainLoop;
