#!/usr/bin/perl -w
# $Id: contours.pl,v 1.8 2003/09/15 12:25:05 mertz Exp $
# This simple demo has been developped by C. Mertz <mertz@cena.fr>

package contours; # for avoiding symbol collision between different demos

use Tk;
use Tk::Zinc;

use strict;

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

my $mw = MainWindow->new();

# The explanation displayed when running this demo
my $text = $mw->Text(-relief => 'sunken', -borderwidth => 2,
		     -setgrid => 'true', -height => 9);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
'All visibles items are made by combining 2 items using contours:
 - the firebrick curve1 has been holed using a addhole with a circle,
 - the lightblue curve2 has been "mickey-moused" by adding two circles,
 - the yellow curve3 is the union with a disjoint circle,
 - the grey curve4 is combined with 7 circles, with \'positive\' -fillrule.
The following operations are possible:
 - "Mouse Button 1" for dragging objects.
 - "Mouse Button 1" for dragging the black handle and
    modifying the grey curve contour.');

# Creating the zinc widget
my $zinc = $mw->Zinc(-width => 600, -height => 500,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;


# Creation of 2 items NOT visible, but used for creating visible
# curves[1-5] with more than one contours.
# The center of these 2 items is 200,100
my $curve0 = $zinc->add('curve', 1, [ [300,0], [400,100, 'c'], [300,200], [200,300,'c'], [100,200], [0,100,'c'], [100,0],  ],
			-closed => 1, -visible => 0, -filled => 1,
			);
my $cercle100 = $zinc->add('arc', 1, [130,30, 280,180],
			  -visible => 0,
			  );

# cloning curve0 as curve1 and moving it
my $curve1 = $zinc->clone($curve0, -visible => 1, -fillcolor => "firebrick1");
# adding a 'difference' contour to the curve1
$zinc->contour($curve1, 'add', +1, $cercle100);


# cloning curve0 as curve2 and moving it
# creating a curve without contour to control contour clockwise/counterclockwise
my $curve2 = $zinc->add('curve', 1, [], -closed => 1, -filled => 1,
			-visible => 1, -fillcolor => "lightblue2", -fillrule => 'positive');
$zinc->contour($curve2, 'add', -1, $curve0); ## why must the flag be -1 and not -1 !?
# adding the left ear of mickey mouse!
$zinc->translate($curve2,100,90);
# adding the right ear of mickey mouse!
$zinc->contour($curve2, 'add', +1, $cercle100);

$zinc->translate($curve2,-200,0);
# adding an 'intersection' contour to the curve2
$zinc->contour($curve2, 'add', +1, $cercle100);

# ... translate to make it more visible
$zinc->translate($curve2, 320,20);


# cloning curve0 as curve3 and moving it
my $curve3 = $zinc->clone($curve0, -visible => 1, -fillcolor => "yellow3");
$zinc->translate($curve3,0,290);
# adding an 'union' contour to the curve3
$zinc->contour($curve3, 'add', +1, $cercle100);
# ... translate to make it more visible
$zinc->translate($curve3, -130,00);

    


# cloning curve0 as curve4 and moving it slightly
my $curve4 = $zinc->clone($curve0, -visible => 1, -fillcolor => "grey50",
			  -tags => ["grouped"],
			  -fillrule => 'positive',
                          # the tag "grouped" is used for both curve4 and
			  # a handle (see just below)
			  # It is used for translating both easily
			  );

my $index = 2; ## index of the vertex associated to the handle
my ($x,$y) = $zinc->coords($curve4,0,$index);
my $handle = $zinc->add('rectangle', 1, [$x-5,$y-5,$x+5,$y+5],
			-fillcolor => 'black', -filled => 1,
			  -tags => ["grouped"],
			);

# adding a 'difference' contour to the curve4
$zinc->contour($curve4, 'add', +1, $cercle100);
$zinc->translate('grouped',110,0);
$zinc->contour($curve4, 'add', +1, $cercle100);
$zinc->translate('grouped',-220,0);
$zinc->contour($curve4, 'add', +1, $cercle100);
$zinc->translate('grouped',110,80);
$zinc->contour($curve4, 'add', -1, $cercle100);
$zinc->translate('grouped',0,-160);
$zinc->contour($curve4, 'add', +1, $cercle100);

$zinc->translate('grouped',200,80);
$zinc->contour($curve4, 'add', +1, $cercle100);
$zinc->translate('grouped',-350,0);
$zinc->contour($curve4, 'add', +1, $cercle100);

$zinc->translate('grouped',350,250);
#$zinc->lower('grouped');

# Deleting no more usefull items: curve0 and cercle100:
$zinc->remove($curve0, $cercle100);

$zinc->raise($curve1);

# adding drag and drop callback to each visible curve!
foreach my $item ($curve1, $curve2, $curve3, $curve4) {
    # Some bindings for dragging the items
    $zinc->bind($item, '<ButtonPress-1>' => [\&press, $item, \&motion]);
    $zinc->bind($item, '<ButtonRelease-1>' => \&release);
}

# adding drag and drop on curve4 which also moves handle
$zinc->bind($curve4, '<ButtonPress-1>' => [\&press, $curve4, \&motionWithHandle]);
$zinc->bind($curve4, '<ButtonRelease-1>' => \&release);

# adding drag and drop on handle which also modify curve4
$zinc->bind($handle, '<ButtonPress-1>' => [\&press, $handle, \&moveHandle]);
$zinc->bind($handle, '<ButtonRelease-1>' => \&release);

# callback for starting a drag
my ($x_orig, $y_orig);
sub press {
    my ($zinc, $item, $action) = @_;
    my $ev = $zinc->XEvent();
    $x_orig = $ev->x;
    $y_orig = $ev->y;
    $zinc->Tk::bind('<Motion>', [$action, $item]);
}

# Callback for moving an item
sub motion {
    my ($zinc, $item) = @_;
    my $ev = $zinc->XEvent();
    my $x = $ev->x;
    my $y = $ev->y;

    $zinc->translate($item, $x-$x_orig, $y-$y_orig);
    $x_orig = $x;
    $y_orig = $y;
}

# Callback for moving an item and its handle
sub motionWithHandle {
    my ($zinc, $item) = @_;
    my $ev = $zinc->XEvent();
    my $x = $ev->x;
    my $y = $ev->y;

    my ($tag) = $zinc->itemcget($item, -tags);
    $zinc->translate($tag, $x-$x_orig, $y-$y_orig);
    $x_orig = $x;
    $y_orig = $y;
}

# Callback for moving the handle and modifying curve4
# this code is far from being generic. Only for demonstrating how we can
# modify a contour with a unique handle!
sub moveHandle {
    my ($zinc, $handle) = @_;
    my $ev = $zinc->XEvent();
    my $x = $ev->x;
    my $y = $ev->y;

    $zinc->translate($handle, $x-$x_orig, $y-$y_orig);

    my ($vertxX,$vertxY) = $zinc->coords($curve4,0,$index);
    $zinc->coords($curve4,0,$index, [$vertxX+($x-$x_orig), $vertxY+($y-$y_orig)]);
    $x_orig = $x;
    $y_orig = $y;
}

# Callback when releasing the mouse button. It removes any motion callback
sub release {
    my ($zinc) = @_;
    $zinc->Tk::bind('<Motion>', '');
}

Tk::MainLoop();


1;
