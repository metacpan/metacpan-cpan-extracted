#!/usr/bin/perl
# $Id: triangles.pl,v 1.4 2004/04/30 11:35:18 lecoanet Exp $
# these simple samples have been developped by C. Mertz mertz@cena.fr and N. Banoun banoun@cena.fr

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;


my $defaultfont = '-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*';
my $mw = MainWindow->new();
my $zinc = $mw->Zinc(-width => 700, -height => 300,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -render => 1,
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

# 6 equilateral triangles around a point 
$zinc->add('text', 1,
	     -position => [ 5,10 ],
	     -text => "Triangles item without transparency");

my ($x0,$y0) = (200,150);
my @coords=($x0,$y0);
for my $i (0..6) {
    my $angle =  $i * 6.28/6;
    push @coords, ($x0 + 100 * cos ($angle), $y0 - 100 * sin ($angle) );
}

my $tr1 = $zinc->add('triangles', 1,
		     \@coords,
		     -fan => 1,
		     -colors => ['white', 'yellow', 'magenta', 'blue', 'cyan', 'green', 'red', 'yellow'],
		     -visible => 1,			    
		     );

$zinc->add('text', 1,
	   -position => [ 370, 10 ],
	   -text => "Triangles item with transparency");


# using the clone method to make a copy and then modify the clone'colors
my $tr2 = $zinc->clone($tr1);
$zinc->translate($tr2,300,0);
$zinc->itemconfigure($tr2,
		     -colors => ['white;50', 'yellow;50', 'magenta;50', 'blue;50', 'cyan;50', 'green;50', 'red;50', 'yellow;50'],
		     );



MainLoop;

		    
	   
