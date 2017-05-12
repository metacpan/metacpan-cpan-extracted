#!/usr/bin/perl -w
# $Id: items.pl,v 1.6 2004/04/30 11:35:18 lecoanet Exp $
# these simple samples have been developped by C. Mertz mertz@cena.fr

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;

my $defaultfont = '-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*';
my $mw = MainWindow->new();
my $zinc = $mw->Scrolled('Zinc', -width => 700, -height => 600,
			 -font => '10x20', -borderwidth => 3,
			 -relief => 'sunken', -scrollbars => 'se',
			 -scrollregion => [-100, 0, 1000, 1000]);
$zinc->pack(-expand => 'yes', -fill => 'both');

$zinc->add('rectangle', 1, [10,10, 100, 50], -fillcolor => "green", -filled => 1,
	    -linewidth => 10, -relief => "roundridge", -linecolor => "darkgreen");


$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "A filled rectangle with a \"roundridge\" relief border of 10 pixels.",
	   -anchor => 'nw',
	   -position => [120, 20]);


my $labelformat = "x82x60+0+0 x60a0^0^0 x32a0^0>1 a0a0>2>1 x32a0>3>1 a0a0^0>2";

my $x=20;
my $y=120;
my $track=$zinc->add('track', 1, 6, # 6 is the number of fields in the flightlabel
		     -labelformat => $labelformat,
		     -position => [$x, $y],
		     -speedvector => [40, -10],
		     -speedvectormark =>  1, # currently works only with openGL
		     -speedvectorticks => 1, # currently works only with openGL
		     );
# moving the track, to display past positions
foreach my $i (0..5) {  $zinc->coords("$track",[$x+$i*10,$y-$i*2]); }

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "A flight track for a radar display. (A waypoint looks similar,\n".
	   "but has no speedvector neither past positions)",
	   -anchor => 'nw',
	   -position => [200, 80],
	   );

$zinc->itemconfigure($track, 0,
		     -filled => 0,
		     -bordercolor => 'DarkGreen',
		     -border => "contour",
		     );
$zinc->itemconfigure($track, 1,
		     -filled => 1,
		     -backcolor => 'gray60',
		     -text => "AFR001");
$zinc->itemconfigure($track, 2,
		     -filled => 0,
		     -backcolor => 'gray65',
		     -text => "360");
$zinc->itemconfigure($track, 3,
		     -filled => 0,
		     -backcolor => 'gray65',
		     -text => "/");
$zinc->itemconfigure($track, 4,
		     -filled => 0,
		     -backcolor => 'gray65',
		     -text => "410");
$zinc->itemconfigure($track, 5,
		     -filled => 0,
		     -backcolor => 'gray65',
		     -text => "Beacon");





$zinc->add('arc', 1, [150, 140, 450, 240], -fillcolor => "gray20",
	   -filled => 0,  -linewidth => 1,
	   -startangle => 45, -extent => 270);
$zinc->add('arc', 1, [260, 150, 340, 230], -fillcolor => "gray20",
	   -filled => 0,  -linewidth => 1,
	   -startangle => 45, -extent => 270,
	   -pieslice => 1, -closed => 1,
	   -linestyle => 'mixed', -linewidth => 3,
	   );

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "Two arcs, starting at 45° with an extent of 270°.",
	   -anchor => 'nw',
	   -position => [320, 180]);


$zinc->add('curve', 1, [10, 324, 24, 300, 45, 432, 247, 356, 128, 401],
	   -filled => 0, -relief => 'roundgroove',
           # -linewidth => 10, ## BUG with zinc 3.2.3g 
	   );
$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "An open curve.",
	   -anchor => 'nw',
	   -position => [50, 350]);


$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "A waypoint",
	   -anchor => 'nw',
	   -position => [10, 480],
	   );
my $waypoint = $zinc->add('waypoint', 1, 6, -position => [100,520],
			  -labelformat => $labelformat,
			  -symbol => "AtcSymbol2",
			  -labeldistance => 30);  

foreach my $fieldId (1..5) {
    $zinc->itemconfigure($waypoint, $fieldId,
			 -filled => 0,
			 -bordercolor => 'DarkGreen',
			 -border => "contour",  # does not work with openGL (zinc-perl v3.2.3e)
			 -text => "field$fieldId",
			 );
}


$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "3 tabulars of 2 fields,\nattached together.",
	   -anchor => 'nw',
	   -position => [510, 380],
	   );

my $labelformat2 = "x72x40 x72a0^0^0 x34a0^0>1";

my $tabular1 = $zinc->add('tabular', 1, 6, -position => [570,250],
			  -labelformat => $labelformat2,
			  );
my $tabular2 = $zinc->add('tabular', 1, 6, -connecteditem => $tabular1,
			  -labelformat => $labelformat2,
			  );
my $tabular3 = $zinc->add('tabular', 1, 6, -connecteditem => $tabular2,
			  -labelformat => $labelformat2,
			  );
my $count=1;
foreach my $tab ($tabular1, $tabular2, $tabular3) {
    $zinc->itemconfigure($tab, 1, -filled => 0,
			 -bordercolor => 'DarkGreen',
			 -border => "contour", -text => "tabular",
			 );
    $zinc->itemconfigure($tab, 2, -filled => 0,
			 -bordercolor => 'DarkGreen',
			 -border => "contour", -text => "n°$count",
			 );
    $count++;
}


$zinc->add('reticle', 1, -position => [530,550],
	   -firstradius => 20, -numcircles => 6,
	   -period => 2, -stepsize => 20,
	   -brightlinestyle => 'dashed', -brightlinecolor => 'darkred', 
	   );

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "a reticle of 6 circles.",
	   -anchor => 'nw',
	   -position => [530, 540]);



$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "maps, triangles and groups items\nare not demonstrated here.",
	   -anchor => 'nw',
	   -position => [10, 550]);



MainLoop;

