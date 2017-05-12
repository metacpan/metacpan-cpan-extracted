#!/usr/bin/perl
# $Id: mapinfo.pl,v 1.4 2004/04/30 11:35:18 lecoanet Exp $
# This simple demo has been developped by C. Schlienger <celine@intuilab.com>

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;


my $defaultfont = '-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*';
my $mw = MainWindow->new();

###########################################
# Text zone
###########################################

my $text = $mw->Text(-relief => 'sunken', -borderwidth => 2,
		     -height => 4);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
	      'This toy-appli shows zoom actions on map item.
The following operations are possible:
   Click "-" to zoom out
   Click "+" to zoom in ' );

###########################################
# Zinc
###########################################
my $zinc_width=600;
my $zinc_height=500;
my $zinc = $mw->Zinc(-width => $zinc_width, -height => $zinc_height,
		     -font => "10x20",
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

###########################################
# Waypoints and sector
###########################################

my $mapinfo=$mw->mapinfo("mapinfo","create"); #creation of mapinfo

#--------------------------------
# Waypoints
#--------------------------------
$mw->mapinfo("mapinfo","add","symbol",200,100,0);
$mw->mapinfo("mapinfo","add","symbol",300,150,0);
$mw->mapinfo("mapinfo","add","symbol",400,50,0);
$mw->mapinfo("mapinfo","add","symbol",350,450,0);
$mw->mapinfo("mapinfo","add","symbol",300,250,0);
$mw->mapinfo("mapinfo","add","symbol",170,240,0);
$mw->mapinfo("mapinfo","add","symbol",550,200,0);

#--------------------------------
# Waypoints names
#--------------------------------
$mw->mapinfo("mapinfo","add","text","normal","simple",170,100,"DO");
$mw->mapinfo("mapinfo","add","text","normal","simple",270,160,"RE");
$mw->mapinfo("mapinfo","add","text","normal","simple",410,50,"MI");
$mw->mapinfo("mapinfo","add","text","normal","simple",345,470,"FA");
$mw->mapinfo("mapinfo","add","text","normal","simple",280,265,"SOL");
$mw->mapinfo("mapinfo","add","text","normal","simple",150,240,"LA");
$mw->mapinfo("mapinfo","add","text","normal","simple",555,200,"SI");

#--------------------------------
# Routes
#--------------------------------

$mw->mapinfo("mapinfo","add","line","simple",1,200,100,300,150);
$mw->mapinfo("mapinfo","add","line","simple",1,300,150,400,50);
$mw->mapinfo("mapinfo","add","line","simple",1,300,150,350,450);
$mw->mapinfo("mapinfo","add","line","simple",1,300,250,170,240);
$mw->mapinfo("mapinfo","add","line","simple",1,300,250,550,200);

#--------------------------------
# Sectors
#---------------------------------
$mw->mapinfo("mapinfo","add","line","simple",1,300,0,400,50);
$mw->mapinfo("mapinfo","add","line","simple",1,400,50,500,100);
$mw->mapinfo("mapinfo","add","line","simple",1,500,100,550,200);
$mw->mapinfo("mapinfo","add","line","simple",1,550,200,550,400);
$mw->mapinfo("mapinfo","add","line","simple",1,550,400,350,450);
$mw->mapinfo("mapinfo","add","line","simple",1,350,450,170,240);
$mw->mapinfo("mapinfo","add","line","simple",1,170,240,200,100);
$mw->mapinfo("mapinfo","add","line","simple",1,200,100,300,0);

#--------------------------------
# Sectors
#---------------------------------
my $gpe = $zinc ->add('group',1);
my $map = $zinc ->add('map',$gpe,#creation of the map object which has 'mapinfo' information
		      -mapinfo=>"mapinfo",
		      -symbols=>['AtcSymbol15']);


###################################################
# control panel
###################################################
my $rc = $mw->Frame()->pack();

#the reference of the scale function is top-left corner of the zinc object
#so we first translate the group to zoom in order to put its center on top-left corner
#change the scale of the group
#translate the group to put it back at the center of the zinc object 

my $minus=$rc->Button(-width => 2, 
		      -height => 2,
		      -text => '-',
		      -command=>sub{
			$zinc->translate($gpe,-$zinc_width/2,-$zinc_height/2);
			$zinc->scale($gpe,0.8,0.8);
			$zinc->translate($gpe, $zinc_width/2,$zinc_height/2);
		      })->pack(-side=>'left');


my $plus=$rc->Button(-width => 2, 
		     -height => 2,
		     -text => '+',
		     -command=>sub{
		       $zinc->translate($gpe, -$zinc_width/2,-$zinc_height/2);
		       $zinc->scale($gpe,1.2,1.2);
		       $zinc->translate($gpe,$zinc_width/2,$zinc_height/2);
		     })->pack(-side => 'right');



MainLoop;
