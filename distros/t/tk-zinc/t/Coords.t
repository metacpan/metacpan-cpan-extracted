#!/usr/bin/perl -w

#
# $Id: Coords.t,v 1.7 2005/06/23 15:32:39 mertz Exp $
# Author: Christophe Mertz
#

# testing all the import

BEGIN {
    if (!eval q{
        use Test::More tests => 26;
        1;
    }) {
        print "# tests only work properly with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
    if (!eval q{
	use Tk::Zinc;
 	1;
    }) {
        print "unable to load Tk::Zinc";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
    if (!eval q{
 	MainWindow->new();
 	1;
    }) {
        print "# tests only work properly when it is possible to create a mainwindow in your env\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
}


$mw = MainWindow->new();
$zinc = $mw->Zinc(-width => 100, -height => 100);

like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");

my $rect = $zinc->add('rectangle', 1, [10,20,40,50]);


is_deeply([ $zinc->coords($rect) ],
	  [ [10,20], [40, 50] ],
	  "coords are list of arrays");

is_deeply([ $zinc->coords($rect,0) ],
	  [ [10,20], [40, 50] ],
	  "coords of first contour is a list of arrays");

is_deeply([ $zinc->coords($rect,0,0) ],
	  [ 10,20 ],
	  "coords of one point of a contour is a list of two numbers");

is_deeply([ $zinc->coords($rect,0,1) ],
	  [ 40,50 ],
	  "coords of one point of a contour is a list of two numbers");

my $curve = $zinc->add('curve', 1, [ [10,20] ,[40,50,'c'], [90,10,'c'], [30,60] ]);

is_deeply([ $zinc->coords($curve) ],
	  [ [10,20] ,[40,50,'c'], [90,10,'c'], [30,60] ],
	  "coords of a curve is a list of arrays");

is_deeply([ $zinc->coords($curve,0) ],
	  [ [10,20] ,[40,50,'c'], [90,10,'c'], [30,60] ],
	  "coords of contour 0 of a curve is a list of arrays");

is_deeply([ $zinc->coords($curve,0,0) ],
	  [ 10,20 ],
	  "coords of first point of contour 0 of a curve is list of two numbers");

is_deeply([ $zinc->coords($curve,0,1) ],
	  [ 40,50,'c' ],
	  "coords of a control point of a curve contour is list of three elements");



## testing empty curves, and adding/removing contours
my $emptyCurve = $zinc->add('curve', 1, [ ]);

is_deeply([ $zinc->coords($emptyCurve) ],
	  [  ],
	  "coords of an empty curve is an empty list");

# adding a contour
$zinc->contour($emptyCurve, 'add', 0, [ [1,1], [100,100], [200,100] ]);
is_deeply([ $zinc->coords($emptyCurve) ],
	  [  [1,1], [100,100], [200,100] ],
	  "coords of a no more empty curve");

$zinc->contour($emptyCurve, 'add', 0, [ [80,90], [-100,-100], [-200,100] ]);
is_deeply([ $zinc->coords($emptyCurve, 1) ],
	  [  [80,90], [-100,-100], [-200,100] ],
	  "coords of a second contour in a curve");

# removing first contour (which can be the second one!!
$zinc->contour($emptyCurve, 'remove', 0);
is_deeply([ $zinc->coords($emptyCurve, 0) ],
	  [  [1,1], [100,100], [200,100] ],   # contours order is re-organised by tkzinc!!
#	  [  [80,90], [-100,-100], [-200,100] ],
	  "coords of remaining contour in the curve");

# removing the last contour
$zinc->contour($emptyCurve, 'remove', 0);
is_deeply([ $zinc->coords($emptyCurve, 0) ],
	  [   ],
	  "coords of contour in the curve which is now empty");





my $text = $zinc->add('text', 1, -position => [10,20], -text => 'test');

is_deeply([ $zinc->coords($text) ],
	  [ 10,20 ],
	  "coords of a text");

is_deeply([ $zinc->coords($text,0) ],
	  [ 10,20 ],
	  "coords of text contour");

is_deeply([ $zinc->coords($text,0,0) ],
	  [ 10,20 ],
	  "coords of text contour first point");


my $group = $zinc->add('group', 1);

is_deeply([ $zinc->coords($group) ],
	  [ 0,0 ],
	  "coords of a empty group, not moved");

$zinc->translate($group, 23, 45);
#my @coords = @{$zinc->coords($group)}[0];
#print "coords = @coords", $coords[0][0], $coords[0][1], "\n";
is_deeply([ $zinc->coords($group) ],
	  [ 23,45 ],
	  "coords of a empty group, translated");


my $track = $zinc->add('track', 1, 0, -position => [56, 78]);
is_deeply([ $zinc->coords($track) ],
	  [ 56,78 ],
	  "coords of a track");

my $wpt = $zinc->add('waypoint', 1, 0, -position => [561, 781]);
is_deeply([ $zinc->coords($wpt) ],
	  [ 561,781 ],
	  "coords of a waypoint");

my $tab = $zinc->add('tabular', 1, 1, -position => [61, 81]);
is_deeply([ $zinc->coords($tab) ],
	  [ 61,81 ],
	  "coords of a empty tabular");
$zinc->itemconfigure($tab, -labelformat => 'x20x18+0+0');
is_deeply([ $zinc->coords($tab) ],
	  [ 61,81 ],
	  "coords of a tabular with a labelformat");


my $arc = $zinc->add('arc', 1, [13,31, 42,24]);
is_deeply([ $zinc->coords($arc) ],
	  [ [13,31],  [42,24] ],
	  "coords of an arc");

my $tri = $zinc->add('triangles', 1, [ [10,20],  [30,40], [50,60], [70,80], [90,99] ]);
is_deeply([ $zinc->coords($tri) ],
	  [ [10,20],  [30,40], [50,60], [70,80], [90,99] ],
	  "coords of an triangle");

my $photoMickey = $zinc->Photo('mickey.gif', -file => Tk->findINC("demos/images/mickey.gif"));
my $icon = $zinc->add('icon', 1, -position => [20,100], -image => $photoMickey);
is_deeply([ $zinc->coords($icon) ],
	  [ 20,100 ],
	  "coords of an icon");

diag("############## coords test");


