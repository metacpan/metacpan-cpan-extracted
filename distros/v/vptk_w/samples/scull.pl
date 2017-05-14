#!/usr/local/bin/perl

use strict;
use Tk;
use Tk::Canvas;
my $mw=MainWindow->new();


my $c=$mw->Canvas(-width=>313,-height=>275)->pack;


# Scull (c) Felix Liberman 
$c->configure(-background=>'gray');
my $cnv_Splash_1 = $c->create('polygon',172.00,37.00,176.00,101.00,130.00,104.00,-smooth,1.00,-tags=>['cnv_Splash_1','cnv_obj']);
my $cnv_Chord_2 = $c->create('arc',127.00,28.00,228.00,163.00,-start,313.00,-extent,275.00,-style,'chord',-tags=>['cnv_Chord_2','cnv_obj']);
my $cnv_Splash_3 = $c->create('polygon',173.00,98.00,185.00,127.00,160.00,126.00,-smooth,1.00,-tags=>['cnv_Splash_3','cnv_obj']);
my $cnv_Splash_4 = $c->create('polygon',180.00,98.00,168.00,127.00,193.00,126.00,-smooth,1.00,-tags=>['cnv_Splash_4','cnv_obj']);
my $cnv_Splash_5 = $c->create('polygon',184.00,37.00,180.00,101.00,226.00,104.00,-smooth,1.00,-tags=>['cnv_Splash_5','cnv_obj']);
my $cnv_Chord_6 = $c->create('arc',145.00,65.00,214.00,180.00,-start,212.00,-extent,116.00,-style,'chord',-tags=>['cnv_Chord_6','cnv_obj']);

MainLoop;
