#!/usr/bin/perl
# $Id: color-path-and-conic.pl,v 1.4 2004/04/30 11:35:18 lecoanet Exp $
# these simple samples have been developped by C. Mertz mertz@cena.fr

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

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


$zinc->add('rectangle', 1, [10, 10, 80, 80], -fillcolor => "=path 0 0 |red |blue", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "Path variation from non-transparent red to non-transparent blue\nin a squarre. The gradient start at the middle of the bbox.",
	   -anchor => 'nw',
	   -position => [120, 20]);

$zinc->add('arc', 1, [10, 110, 90, 190], -fillcolor => "=conical 135 |black;40|white;40", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "Conical variation from 40%transparent black to 40% transparent white\nin a disc, center in the middle of the bbox",
	   -anchor => 'nw',
	   -position => [120, 120]);


$zinc->add('arc', 1, [10, 210, 90, 290], -fillcolor => "=path -30 +30 |red;40|green;40 50|blue;40", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "A path variation from 40%transparent red to 40% transparent blue.\n".
	   "through a 40%green on the middle of the disc. The gradient center\nis toward the SW of the bbox.",
	   -anchor => 'nw',
	   -position => [120, 220]);



$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "overlaping path and conical, transparently colored items on a white background",
	   -anchor => 'nw',
	   -position => [20, 320]);

$zinc->add('rectangle', 1, [10, 340, 690, 590], -fillcolor => "white", -filled => 1);

$zinc->add('rectangle', 1, [20, 365, 220, 565], -fillcolor => "=path -40 -40 |red;40|green;40 50|blue;40", -filled => 1);

$zinc->add('arc', 1, [150, 365, 350, 565], -fillcolor => "=conical 20 -30 45 |yellow;40|black;40 50|cyan;40", -filled => 1);

$zinc->add('arc', 1, [320, 365, 480, 565], -fillcolor => "=path 0 0 |black;100|black;100 20|white;40", -filled => 1, -linewidth => 0);

#$zinc->add('arc', 1, [480, 365, 580, 500], -fillcolor => "=radial -10 16 |black;100|white;40", -filled => 1);

$zinc->add('arc', 1, [580, 410, 680, 580], -fillcolor => "=conical -40 -40 135 |black;70|white;20", -filled => 1);
#$zinc->add('arc', 1, [580, 410, 680, 580], -fillcolor => "=radial 40 40 |black;70|white;20", -filled => 1);


$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "WITHOUT openGL, NO GRADIENT. SORRY!",
	   -anchor => 'nw',
	   -position => [20, 550]) unless $zinc->cget(-render);

MainLoop;

