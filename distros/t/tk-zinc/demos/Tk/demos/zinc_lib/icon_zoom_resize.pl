#!/usr/bin/perl
# $Id: icon_zoom_resize.pl,v 1.7 2004/04/30 11:35:18 lecoanet Exp $
# this simple demo has been developped by C. Mertz <mertz@cena.fr>

package icon_zoom__resize; # for avoiding symbol re-use between different demos

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;


my $defaultfont = '-adobe-helvetica-bold-r-normal--*-140-*-*-*-*-*-*';
my $mw = MainWindow->new();
my $text = $mw->Scrolled(qw/Text -relief sunken -borderwidth 2 -setgrid true
	      -height 7 -scrollbars ''/);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
	      'This demo needs openGL for rescaling/rotating the icon
   You can transform this earth gif image with your mouse:
     Drag-Button 1 for zooming the earth,
     Drag-Button 2 for rotating the earth,
     Drag-Button 3 for moving the earth,
     Shift-Drag-Button 1 for modifying the earth transparency'
	      );

my $zinc = $mw->Zinc(-width => 350, -height => 250,
		     -render => 1,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

my $earth_group = $zinc->add('group', 1, );

# the following image is included in Perl/Tk distrib
my $image = $zinc->Photo('earth.gif', -file => Tk->findINC('demos/images/earth.gif'));

my $earth = $zinc->add('icon', $earth_group,
		      -image => $image,
		      -composescale => 1,
		      -composerotation => 1,
		      );
$zinc->add('text', $earth_group,
           -position => [30,30],
#	   -connecteditem => $earth,
	   -text => "try to zoom/resize the earth!\nWorks even without openGL!!",
	   -color => "white",
	   -composescale => 1,
	   -composerotation => 1,
	   );

$zinc->Tk::bind('<ButtonPress-1>', [\&press, \&zoom]);
$zinc->Tk::bind('<ButtonRelease-1>', [\&release]);

$zinc->Tk::bind('<ButtonPress-2>', [\&press, \&rotate]);
$zinc->Tk::bind('<ButtonRelease-2>', [\&release]);

$zinc->Tk::bind('<ButtonPress-3>', [\&press, \&motion]);
$zinc->Tk::bind('<ButtonRelease-3>', [\&release]);
    

$zinc->Tk::bind('<Shift-ButtonPress-1>', [\&press, \&modifyAlpha]);
$zinc->Tk::bind('<Shift-ButtonRelease-1>', [\&release]);



#
# Controls for the window transform.
#
my ($cur_x, $cur_y, $cur_angle);
sub press {
    my ($zinc, $action) = @_;
    my $ev = $zinc->XEvent();
    $cur_x = $ev->x;
    $cur_y = $ev->y;
    $cur_angle = atan2($cur_y, $cur_x);
    $zinc->Tk::bind('<Motion>', [$action]);
}

sub modifyAlpha {
    my ($zinc) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $xrate = $lx /  $zinc->cget(-width);

    $xrate = 0 if $xrate < 0;
    $xrate = 1 if $xrate > 1;

    my $alpha = $xrate * 100;
    
    $zinc->itemconfigure($earth_group, -alpha => $alpha);
}


sub motion {
    my ($zinc) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my @res;
    
    @res = $zinc->transform($earth_group, [$lx, $ly, $cur_x, $cur_y]);
    $zinc->translate($earth_group, $res[0] - $res[2], $res[1] - $res[3]);
    $cur_x = $lx;
    $cur_y = $ly;
}

sub zoom {
    my ($zinc, $self) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my $maxx;
    my $maxy;
    my $sx;
    my $sy;
    
    if ($lx > $cur_x) {
	$maxx = $lx;
    } else {
	$maxx = $cur_x;
    }
    if ($ly > $cur_y) {
	$maxy = $ly
    } else {
	$maxy = $cur_y;
    }
    return if ($maxx == 0 || $maxy == 0);
    $sx = 1.0 + ($lx - $cur_x)/$maxx;
    $sy = 1.0 + ($ly - $cur_y)/$maxy;
    $cur_x = $lx;
    $cur_y = $ly;
    $zinc->scale($earth_group, $sx, $sy);
}

sub rotate {
    my ($zinc) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my $langle;
    
    $langle = atan2($ly, $lx);
    $zinc->rotate($earth_group, -($langle - $cur_angle));
    $cur_angle = $langle;
}

sub release {
    my ($zinc) = @_;
    $zinc->Tk::bind('<Motion>', '');
}

Tk::MainLoop;
