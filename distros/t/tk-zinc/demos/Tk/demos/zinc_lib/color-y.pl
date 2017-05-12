#!/usr/bin/perl
# $Id: color-y.pl,v 1.6 2004/04/30 11:35:18 lecoanet Exp $
# these simple samples have been developped by C. Mertz mertz@cena.fr

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;

my $defaultfont = '-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*';
my $mw = MainWindow->new();
my $zinc = $mw->Zinc(-width => 700, -height => 600,
		     -borderwidth => 3, -relief => 'sunken',
		     -render => 1, # for activating the openGL render
		     )->pack;

# This demo no more dies if there is no openGL. It simply displays
# a string on the bootom of the window!


$zinc->add('rectangle', 1, [10, 10, 340, 100], -fillcolor => "=axial 90 |red |blue", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "A variation from non transparent red\n to non transparent blue.",
	   -anchor => 'nw',
	   -position => [20, 20]);


$zinc->add('rectangle', 1, [360, 10, 690, 100], -fillcolor => "=axial 0 30 0 -30 |red |blue", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "The same with a reduced span.",
	   -anchor => 'nw',
	   -position => [370, 20]);



$zinc->add('rectangle', 1, [10,110, 330, 200], -fillcolor => "=axial 90|red;40 |blue;40", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "A variation from 40%transparent red\nto 40% transparent blue.",
	   -anchor => 'nw',
	   -position => [20, 120]);


$zinc->add('rectangle', 1, [360,110, 690, 200], -fillcolor => "=axial 0 30 0 -30|red;40 |blue;40", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "The same with a reduced span.",
	   -anchor => 'nw',
	   -position => [370, 120]);


$zinc->add('rectangle', 1, [10, 210, 690, 300], -fillcolor => "=axial 90 |red;40|green;40 50|blue;40", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "A variation from 40%transparent red to 40% transparent blue.\n".
	   "through a 40%green on the middle",
	   -anchor => 'nw',
	   -position => [20, 220]);


$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "Two overlaping transparently colored rectangles on a white background",
	   -anchor => 'nw',
	   -position => [20, 320]);

$zinc->add('rectangle', 1, [10, 340, 690, 590], -fillcolor => "white", -filled => 1);
$zinc->add('rectangle', 1, [200, 350, 500, 580], -fillcolor => "=axial 90 |red;40|green;40 50|blue;40", -filled => 1);

$zinc->add('rectangle', 1, [10, 400, 690, 500], -fillcolor => "=axial 90 |yellow;40|black;40 50|cyan;40", -filled => 1);


$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "WITHOUT openGL, NO GRADIENT. SORRY!",
	   -anchor => 'nw',
	   -position => [20, 550]) unless $zinc->cget(-render);



MainLoop;

