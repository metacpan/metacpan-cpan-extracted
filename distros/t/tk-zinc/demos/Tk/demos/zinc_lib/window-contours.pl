#!/usr/bin/perl -w
# $Id: window-contours.pl,v 1.6 2003/09/15 12:25:05 mertz Exp $
# This simple demo has been developped by C. Mertz <mertz@cena.fr>

package window_contours; # for avoiding symbol collision between different demos

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;

use strict;

my $mw = MainWindow->new();


# Creating the zinc widget
my $zinc = $mw->Zinc(-width => 600, -height => 500,
		     -font => "9x15", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

# The explanation displayed when running this demo
$zinc->add('text', 1,
	   -position=> [10,10],
	   -text => 'These "windows" are simply rectangles holed by 4 smaller
rectangles. The text appears behind the window glasses.
You can drag text or "windows".',
	   -font => "10x20",
	   );

# Text in background
my $backtext = $zinc->add('text', 1,
			  -position=> [50,200],
			  -text => "This  text  appears\nthrough holes of  curves",
			  -font => "-adobe-helvetica-bold-o-normal--34-240-100-100-p-182-iso8859-1",
			  );

my $window = $zinc->add('curve', 1, [100,100 , 300,100, 300,400 , 100,400 ],
			-closed => 1, -visible => 1, -filled => 1,
			-fillcolor => "grey66",
			);

my $aGlass= $zinc->add('rectangle', 1, [120,120 , 190,240]);
$zinc->contour($window, 'add', +1, $aGlass);

$zinc->translate($aGlass, 90,0);
$zinc->contour($window, 'add', +1, $aGlass);

$zinc->translate($aGlass, 0,140);
$zinc->contour($window, 'add', +1, $aGlass);

$zinc->translate($aGlass, -90,0);
$zinc->contour($window, 'add', +1, $aGlass);

# deleting $aGlass which is no more usefull
$zinc->remove($aGlass);

# cloning $window
my $window2 = $zinc->clone($window);

# changing its background, moving it and scaling it!
$zinc->itemconfigure($window2, -fillcolor => "grey50");
$zinc->translate($window2, 30,50);
$zinc->scale($window, 0.8, 0.8);




# adding drag and drop callback to the two windows and backtext
foreach my $item ($window, $window2, $backtext) {
    # Some bindings for dragging the items
    $zinc->bind($item, '<ButtonPress-1>' => [\&press, $item, \&motion]);
    $zinc->bind($item, '<ButtonRelease-1>' => \&release);
}

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


# Callback when releasing the mouse button. It removes any motion callback
sub release {
    my ($zinc) = @_;
    $zinc->Tk::bind('<Motion>', '');
}


Tk::MainLoop();


1;
