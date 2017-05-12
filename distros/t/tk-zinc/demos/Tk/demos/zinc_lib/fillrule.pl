#!/usr/bin/perl -w
# $Id: fillrule.pl,v 1.4 2004/09/21 12:47:28 mertz Exp $
# This simple demo has been developped by C. Mertz <mertz@cena.fr>

####### This file has been largely inspired from figure 11-3
####### of "The OpenGL Programming Guide 3rd Edition, The 
####### Official Guide to Learning OpenGL Version 1.2",  ISBN 0201604582

####### it illustrates the use of :
#######   -fillrule attribute of curves
#######   contour, coords and clone method

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use Tk::Zinc;


my $mw = MainWindow->new();
$mw->title('example of multiple contours and fillrule usage');

my $zinc = $mw->Zinc(-width => 510, -height => 630,
		     -font => "10x20",
		     -font => "9x15",
		     -borderwidth => 0,
                     -backcolor => "white",
		      )->pack;

$zinc->add('text', 1, -position => [20,8], -text => "This (still static) example reproduces figure 11-3
of \"The OpenGL Programming Guide 3rd Edition\" V 1.2");

my $group = $zinc->add('group', 1);

my $g1 = $zinc->add('group', $group);
my $curve1 = $zinc->add('curve',$g1, []);
$zinc->contour($curve1, "add", +1, [ 0,0, 0,120, 120,120, 120,0, 0,0]);
$zinc->contour($curve1, "add", +1, [ 20,20, 20,100, 100,100, 100,20, 20,20]);
$zinc->contour($curve1, "add", +1, [ 40,40, 40,80, 80,80, 80,40, 40,40]);
$zinc->translate($g1, 40,40);


my $g2 = $zinc->add('group', $group);
my $curve2 = $zinc->add('curve',$g2, []);
$zinc->contour($curve2, "add", +1, [ 0,0, 0,120, 120,120, 120,0, 0,0]);
$zinc->contour($curve2, "add", -1, [ 20,20, 20,100, 100,100, 100,20, 20,20]);
$zinc->contour($curve2, "add", -1, [ 40,40, 40,80, 80,80, 80,40, 40,40]);
$zinc->translate($g2, 200,40);


my $g3 = $zinc->add('group', $group);
my $curve3 = $zinc->add('curve',$g3, []);
$zinc->contour($curve3, "add", +1, [ 20,0, 20,120, 100,120, 100,0, 20,0]);
$zinc->contour($curve3, "add", +1, [ 40,20, 60,120, 80,20, 40,20]);
$zinc->contour($curve3, "add", +1, [ 0,60, 0,80, 120,80, 120,60, 0,60]);
$zinc->translate($g3, 360,40);

my $g4 = $zinc->add('group', $group);
my $curve4 = $zinc->add('curve',$g4, []);
$zinc->contour($curve4, "add", +1, [ 0,0, 0,140, 140,140,  140,60,  60,60,  60,80, 80,80, 80,40, 40,40,
				     40,100, 100,100, 100,20, 20,20,
				     20,120, 120,120, 120,0, 0,0]);
$zinc->translate($g4, 520,40);

$zinc->scale($group, 0.6, 0.6);
$zinc->translate($group, 80,20);

$zinc->add('text',$group, -position => [-110, 40], -text => "contours\nand\nwinding\nnumbers");
$zinc->add('text',$group, -position => [-110, 170], -text => "winding\nrules");
my $dy = 0;
foreach my $fillrule ('odd', 'nonzero', 'positive', 'negative', 'abs_geq_2') {
    $dy += 160;
    $zinc->add('text',$group, -position => [-110, 100+$dy], -text => $fillrule eq 'odd' ? "odd\n(default)" : $fillrule);
    foreach my $item ($curve1, $curve2, $curve3, $curve4) {
	my $clone = $zinc->clone($item, -fillrule => $fillrule, -filled => 1);
	$zinc->translate($clone, 0,$dy);
    }
}

# creating simple lines with arrows under each curves
foreach my $item ($curve1, $curve2, $curve3, $curve4) {
    my $contour_number = $zinc->contour($item);
#    print "$item => contour_number=$contour_number\n";
    foreach my $n (0..$contour_number-1) {
	my @points = $zinc->coords($item,$n);
#	print "   ",$#points,"points\n";
	foreach my $i (0 .. $#points-1) {
#	    print "    line $i ",$i+1,"\n";
	    $firstpoint = $points[$i];
	    $lastpoint = $points[$i+1];
	    $middlepoint = [$firstpoint->[0]+($lastpoint->[0]-$firstpoint->[0])/1.5,
			    $firstpoint->[1]+($lastpoint->[1]-$firstpoint->[1])/1.5];
	    $zinc->add("curve", $zinc->group($item),
		       [ $firstpoint, $middlepoint],
		       -lastend => [7,10,4]);
	}
    }
}
&Tk::MainLoop;


    
