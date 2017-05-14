#!/usr/local/bin/perl

use strict;
use Tk;
use Tk::Canvas;
my $mw=MainWindow->new();


my $c=$mw->Canvas(-width=>330.25,-height=>246)->pack;


# Propellers
$c->configure(-background=>'gray');
my $cnv_Splash_1 = $c->create('polygon',255.00,246.00,310.50,119.50,178.25,168.75,309.00,222.00,255.50,93.50,197.00,220.00,330.25,169.25,201.50,115.00,-fill,'Red',-smooth,1.00,-tags=>['cnv_Splash_1','cnv_obj']);
my $cnv_Splash_2 = $c->create('polygon',146.00,107.00,162.00,152.00,244.00,180.50,147.00,114.00,89.00,125.00,54.50,188.00,142.00,113.00,169.00,69.50,146.00,2.75,-fill,'magenta1',-smooth,1.00,-tags=>['cnv_Splash_2','cnv_obj']);

MainLoop;
