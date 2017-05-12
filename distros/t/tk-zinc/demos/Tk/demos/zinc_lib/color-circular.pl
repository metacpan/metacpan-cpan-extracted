#!/usr/bin/perl
# $Id: color-circular.pl,v 1.6 2004/04/30 11:35:18 lecoanet Exp $
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


$zinc->add('rectangle', 1, [10, 10, 80, 80], -fillcolor => "=radial 50 50 |red |blue", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "Radial variation from non-transparent red to non-transparent blue\nin a squarre. The gradient starts from the lower right corner.\n",
	   -anchor => 'nw',
	   -position => [120, 20]);

$zinc->add('arc', 1, [10, 110, 90, 190], -fillcolor => "=radial 0 25 |red;40|blue;40", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "Radial variation from 40%transparent red to 40% transparent blue\nin a disc. The gradient starts in the middle between\nthe center on the bottom point",
	   -anchor => 'nw',
	   -position => [120, 120]);

$zinc->add('arc', 1, [10, 210, 90, 290], -fillcolor => "=radial 0 0 |red;40|green;40 50|blue;40", -filled => 1);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "A variation from 40%transparent red to 40% transparent blue.\n".
	   "through a 40%green on the middle of the disc. The gradient is centered.",
	   -anchor => 'nw',
	   -position => [120, 220]);

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "Two overlaping radialy, transparently colored items on a white background",
	   -anchor => 'nw',
	   -position => [20, 320]);

$zinc->add('rectangle', 1, [10, 340, 690, 590], -fillcolor => "white", -filled => 1);

$zinc->add('rectangle', 1, [20, 365, 220, 565], -fillcolor => "=radial 0 0 |red;40|green;40 50|blue;40", -filled => 1);

$zinc->add('arc', 1, [150, 365, 350, 565], -fillcolor => "=radial 0 0 |yellow;40|black;40 50|cyan;40", -filled => 1);

$zinc->add('arc', 1, [280, 365, 480, 565], -fillcolor => "=radial 0 0 |black;100|black;100 20|white;40", -filled => 1, -linewidth => 0);

$zinc->add('arc', 1, [480, 365, 580, 500], -fillcolor => "=radial -10 16 |black;100|white;40", -filled => 1);

$zinc->add('arc', 1, [580, 410, 680, 580], -fillcolor => "=radial -40 -40 |black;70|white;20", -filled => 1);
$zinc->add('arc', 1, [580, 410, 680, 580], -fillcolor => "=radial 40 40 |black;70|white;20", -filled => 1);


$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "WITHOUT openGL, NO GRADIENT. SORRY!",
	   -anchor => 'nw',
	   -position => [20, 550]) unless $zinc->cget(-render);

MainLoop;

