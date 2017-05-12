#!/usr/bin/perl
# $Id: clipping.pl,v 1.7 2004/04/30 11:35:18 lecoanet Exp $
# this simple sample has been developped by C. Mertz mertz@cena.fr

use Tk;
use Tk::Zinc;
use strict;
use Tk::Checkbutton;

package clipping;

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

my $defaultfont = '-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*';
my $mw = MainWindow->new();
my $zinc = $mw->Zinc(-width => 700, -height => 600,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

my $display_clipping_item_background = 0;
my $clip = 1;

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text => "You can drag and drop the objects.\n".
	   "There are two groups of objects, a \"tan group\" and a \"blue group\".\n".
	   "Try to move them and discover the clipping area which is a curve.\n".
	   "with two contours",
	   -anchor => 'nw',
	   -position => [10, 10]);


my $clipped_group = $zinc->add('group', 1, -visible => 1);

my $clipping_item = $zinc->add('curve', $clipped_group,
			       [10,100, 690,100, 690,590, 520,350,
				350,590, 180,350, 10,590],
			       -closed => 1,
			       -priority => 1,
			       -fillcolor => "tan2",
			       -linewidth => 0,
			       -filled => $display_clipping_item_background);
$zinc->contour($clipping_item, "add", +1, [200,200, 500,200, 500,250, 200,250]);

############### creating the tan_group objects ################
# the tan_group is atomic, that is is makes all children as a single object
# and sensitive to tan_group callbacks
my $tan_group = $zinc->add('group', $clipped_group,
			   -visible => 1,
			   -atomic => 1,
			   -sensitive => 1,
			   );

$zinc->add('arc', $tan_group,
	   [200, 220, 280, 300],
	   -filled => 1,  -linewidth => 1,
	   -startangle => 45, -extent => 270,
	   -pieslice => 1, -closed => 1,
	   -fillcolor => "tan",
	   );

$zinc->add('curve', $tan_group,
	   [400,400, 440,450,  400,500, 500,500, 460,450, 500,400],
	   -filled => 1,  -fillcolor => "tan",
	   -linecolor => "tan",
	   );

############### creating the blue_group objects ################
# the blue_group is atomic too, that is is makes all children as a single object
# and sensitive to blue_group callbacks
my $blue_group = $zinc->add('group', $clipped_group,
			    -visible => 1,
			    -atomic => 1,
			    -sensitive => 1,
			    );

$zinc->add('rectangle', $blue_group,
	   [570,180,  470,280],
	   -filled => 1,  -linewidth => 1,
	   -fillcolor => "blue2",
	   );

$zinc->add('curve', $blue_group,
	   [200,400, 200,500, 300,500, 300,400, 300,300],
	   -filled => 1,  -fillcolor => "blue",
	   -linewidth => 0,
	   );


$zinc->itemconfigure($clipped_group, -clip => $clipping_item);


###################### drag and drop callbacks ############
# for both tan_group and blue_group
$zinc->bind($tan_group, '<ButtonPress-1>' => [\&press, $tan_group, \&motion]);
$zinc->bind($tan_group, '<ButtonRelease-1>' => \&release);
$zinc->bind($blue_group, '<ButtonPress-1>' => [\&press, $blue_group, \&motion]);
$zinc->bind($blue_group, '<ButtonRelease-1>' => \&release);

my ($x_orig, $y_orig);
sub press {
    my ($zinc, $group, $action) = @_;
    my $ev = $zinc->XEvent();
    $x_orig = $ev->x;
    $y_orig = $ev->y;
    $zinc->Tk::bind('<Motion>', [$action, $group]);
}

sub motion {
    my ($zinc, $group) = @_;
    my $ev = $zinc->XEvent();
    my $x = $ev->x;
    my $y = $ev->y;

    $zinc->translate($group, $x-$x_orig, $y-$y_orig);
    $x_orig = $x;
    $y_orig = $y;
}

sub release {
    my ($zinc) = @_;
    $zinc->Tk::bind('<Motion>', '');
}
###################### toggle buttons at the bottom #######
my $row = $mw->Frame()->pack();
$row->Checkbutton(-text => 'Show clipping item',
		 -variable => \$display_clipping_item_background,
		 -command => \&display_clipping_area)->pack;	   

$row->Checkbutton(-text => 'Clip',
		 -variable => \$clip,
		 -command => \&clip)->pack;	   

sub display_clipping_area {
    $zinc->itemconfigure($clipping_item, -filled => $display_clipping_item_background);
}

sub clip {
    if ($clip) {
	$zinc->itemconfigure($clipped_group, -clip => $clipping_item);
    }
    else {
	$zinc->itemconfigure($clipped_group, -clip => undef);
    }
}

Tk::MainLoop;
