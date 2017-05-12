#!/usr/bin/perl
# $Id: lines.pl,v 1.3 2004/04/30 11:35:18 lecoanet Exp $
# these simple samples have been developped by C. Mertz mertz@cena.fr

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;

my $defaultfont = '-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*';
my $mw = MainWindow->new();
my $zinc = $mw->Zinc(-width => 700, -height => 600,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "A set of lines with different styles of lines and termination\n".
	   "NB: some attributes such as line styles are not necessarily\n".
	   "  available with an openGL rendering system" ,
	   -anchor => 'nw',
	   -position => [20, 20]);

$zinc-> add('curve', 1, [20, 100, 320, 100]); # default options
$zinc-> add('curve', 1, [20, 120, 320, 120],
	    -linewidth => 20,
	    );
$zinc-> add('curve', 1, [20, 160, 320, 160],
	    -linewidth => 20,
	    -capstyle => "butt",
	    );
$zinc-> add('curve', 1, [20, 200, 320, 200],
	    -linewidth => 20,
	    -capstyle => "projecting",
	    );
$zinc-> add('curve', 1, [20, 240, 320, 240],
	    -linewidth => 20,
	    -linepattern => "AlphaStipple7",
	    -linecolor => "red",
	    );

# right column
$zinc-> add('curve', 1, [340, 100, 680, 100],
	    -firstend => [10, 10, 10],
	    -lastend => [10, 25, 45],
	    );
$zinc-> add('curve', 1, [340, 140, 680, 140],
	    -linewidth => 2,
	    -linestyle => 'dashed',
	    );
$zinc-> add('curve', 1, [340, 180, 680, 180],
	    -linewidth => 4,
	    -linestyle => 'mixed',
	    );
$zinc-> add('curve', 1, [340, 220, 680, 220],
	    -linewidth => 2,
	    -linestyle => 'dotted',
	    );

$zinc->add('curve', 1, [20, 300, 140, 360, 320, 300, 180, 260],
	   -closed => 1,
	   -filled => 1,
	   -fillpattern => "Tk",
	   -fillcolor => "grey60",
	   -linecolor => "red",
	   -marker => "AtcSymbol7",
	   -markercolor => "blue",

	   );


$zinc->add('curve', 1, [340, 300, 440, 360, 620, 300, 480, 260],
	   -closed => 1,
	   -linewidth => 10,
	   -joinstyle => "miter", #"round", # "bevel" | "miter"
	   -linecolor => "red",
	   );
$zinc->add('curve', 1, [400, 300, 440, 330, 560, 300, 480, 280],
	   -closed => 1,
	   -linewidth => 10,
	   -joinstyle => "round", # "bevel" | "miter"
	   -tile => Tk::findINC("Xcamel.gif"),
	   -fillcolor => "grey60",
	   -filled => 1,
	   -linecolor => "red",
	   );

#	   -tile => Tk::findINC("Xcamel.gif"),

MainLoop;


