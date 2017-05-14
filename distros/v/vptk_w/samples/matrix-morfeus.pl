#!/usr/local/bin/perl

use strict;
use Tk;
use Tk::Canvas;
my $mw=MainWindow->new();


my $c=$mw->Canvas(-width=>366.3,-height=>334)->pack;


# Matrix - Morfeus
$c->configure(-background=>'gray');
my $cnv_Polygon_7 = $c->create('polygon',246.00,238.00,297.50,234.50,312.00,331.00,292.50,333.25,273.00,273.50,262.50,333.75,238.00,334.00,-fill,'NavyBlue',-outline,'Black',-width,2.00,-tags=>['cnv_Polygon_7','cnv_obj']);
my $cnv_Polygon_2 = $c->create('polygon',252.00,149.00,274.50,143.50,308.25,151.25,329.19,199.19,316.12,205.12,295.06,170.06,310.00,297.00,236.00,293.00,245.50,176.50,212.00,200.00,200.50,186.00,-tags=>['cnv_Polygon_2','cnv_obj']);
my $cnv_Splash_1 = $c->create('polygon',254.00,111.00,294.50,108.50,281.00,152.00,259.00,148.00,-fill,'gray50',-width,2.00,-outline,'Black',-smooth,1.00,-tags=>['cnv_Splash_1','cnv_obj']);
my $cnv_Splash_3 = $c->create('polygon',203.90,191.20,189.90,168.40,218.30,192.80,196.30,207.20,164.70,181.60,-fill,'gray50',-outline,'Black',-width,2.00,-smooth,1.00,-tags=>['cnv_Splash_3','cnv_obj']);
my $cnv_Splash_4 = $c->create('polygon',327.10,209.80,341.10,232.60,312.70,208.20,334.70,193.80,366.30,219.40,-fill,'gray50',-outline,'Black',-width,2.00,-smooth,1.00,-tags=>['cnv_Splash_4','cnv_obj']);
my $cnv_Oval_5 = $c->create('oval',257.00,124.00,271.00,131.00,-fill,'Black',-tags=>['cnv_Oval_5','cnv_obj']);
my $cnv_Oval_6 = $c->create('oval',270.00,124.00,284.00,131.00,-fill,'Black',-tags=>['cnv_Oval_6','cnv_obj']);

MainLoop;
