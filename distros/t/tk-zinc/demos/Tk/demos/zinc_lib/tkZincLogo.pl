#!/usr/bin/perl
# $Id: tkZincLogo.pl,v 1.11 2004/04/30 11:35:18 lecoanet Exp $
# this simple demo has been adapted by C. Mertz <mertz@cena.fr> from the original
# work of JL. Vinot <vinot@cena.fr>

package tkZincLogo; # for avoiding symbol collision between different demos

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;
use Tk::Zinc::Logo; # this module implements a class which instances are Zinc logo!

my $defaultfont = '-adobe-helvetica-bold-r-normal--*-140-*-*-*-*-*-*';
my $mw = MainWindow->new();
my $text = $mw->Scrolled(qw/Text -relief sunken -borderwidth 2 -setgrid true
	      -height 7 -scrollbars ''/);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
	      'This tkZinc logo should used openGL for a correct rendering!
   You can transform this logo with your mouse:
     Drag-Button 1 for moving the logo,
     Drag-Button 2 for zooming the logo,
     Drag-Button 3 for rotating the logo,
     Shift-Drag-Button 1 for modifying the logo transparency,
     Shift-Drag-Button 2 for modifying the logo gradient.'
	      );

my $zinc = $mw->Zinc(-width => 350, -height => 250,
		     -render => 1,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

my $group = $zinc->add('group', 1, );


my $logo = Tk::Zinc::Logo->new(-widget => $zinc,
			       -parent => $group,
			       -position => [40, 70],
			       -priority => 800,
			       -scale => [.6, .6],
			       );


$zinc->Tk::bind('<ButtonPress-1>', [\&press, \&motion]);
$zinc->Tk::bind('<ButtonRelease-1>', [\&release]);
    
$zinc->Tk::bind('<ButtonPress-2>', [\&press, \&zoom]);
$zinc->Tk::bind('<ButtonRelease-2>', [\&release]);

$zinc->Tk::bind('<ButtonPress-3>', [\&press, \&rotate]);
$zinc->Tk::bind('<ButtonRelease-3>', [\&release]);


$zinc->Tk::bind('<Shift-ButtonPress-1>', [\&press, \&modifyAlpha]);
$zinc->Tk::bind('<Shift-ButtonRelease-1>', [\&release]);

$zinc->Tk::bind('<Shift-ButtonPress-2>', [\&press, \&modifyGradient]);
$zinc->Tk::bind('<Shift-ButtonRelease-2>', [\&release]);


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
    $zinc->itemconfigure($group, -alpha => $alpha);
}

sub modifyGradient {
    my ($zinc) = @_;
    my $ev = $zinc->XEvent();
    my $ly = $ev->y;
    my $yrate = $ly /  $zinc->cget(-height);

    $yrate = 0 if $yrate < 0;
    $yrate = 1 if $yrate > 1;
    my $gradientpercent = sprintf ("%d", $yrate * 100);

    $zinc->itemconfigure ('zinc_shape', -fillcolor => "=axial 270|#ffffff 0 28|#66848c $gradientpercent|#7192aa");    
}


sub motion {
    my ($zinc) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my @res;
    
    @res = $zinc->transform($group, [$lx, $ly, $cur_x, $cur_y]);
    $zinc->translate($group, $res[0] - $res[2], $res[1] - $res[3]);
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
    $zinc->scale($group, $sx, $sy);
}

sub rotate {
    my ($zinc) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my $langle;
    
    $langle = atan2($ly, $lx);
    $zinc->rotate($group, -($langle - $cur_angle));
    $cur_angle = $langle;
}

sub release {
    my ($zinc) = @_;
    $zinc->Tk::bind('<Motion>', '');
}

Tk::MainLoop;
