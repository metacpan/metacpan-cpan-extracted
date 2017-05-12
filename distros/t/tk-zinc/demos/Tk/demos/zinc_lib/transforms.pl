#!/usr/bin/perl -w

# $Id: transforms.pl,v 1.7 2003/09/24 15:10:39 mertz Exp $
# This simple demo has been developped by P. Lecoanet <lecoanet@cena.fr>

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

#
# TODO:
#
# Ajouter la construction des items manquants
#

use Tk;
use Tk::Zinc;

my $currentgroup;
my $currentitem;
my $mw = MainWindow->new();
my $top = 1;

my $inactiveAxisColor = 'black';
my $activeAxisColor = 'red';
my $worldAxisColor = '#a5a5a5';

my $itemtype;
my $composerot = 1;
my $composescale = 1;
my $drag = 0;

my $logo = $mw->Photo(-file => Tk->findINC('demos/zinc_data/zinc_anti.gif'));

my $text = $mw->Text(-relief => 'sunken',
		     -borderwidth => 2,
		     -height => 12);
$text->pack(-expand => 0, -fill => 'x');
$text->insert('0.0', 'Items are always added to the current group.
The available commands are:
   Button 1       on the background, add an item with initial translation
   Button 2       on the background, add a group with initial translation
   Button 1       on item/group axes, select/deselect that item space
   Drag Button 1  on item/group axes, translate that item space
   Del            reset the transformation
   Shift-Del      reset a group direct children transformations
   PageUp/Down    scale up/down
   End/Home       rotate right/left
   Ins            swap the Y axis
   4 arrows       translate in the 4 directions');
$text->configure(-state => 'disabled');

my $zinc = $mw->Zinc(-borderwidth => 3,
		     -highlightthickness => 0,
		     -relief => 'sunken',
		     -render => 0,
		     -takefocus => 1);
$zinc->pack(-expand => 1, -fill => 'both');
$zinc->configure(-width => 500, -height => 500);

my $rc = $mw->Frame()->pack(-expand => 0, -fill => 'x');
my $option = $rc->Optionmenu(-options => ['rectangle', 'arc',
					  'curve',
					  'icon', 'tabular',
					  'text', 'track',
					  'triangles', 'waypoint'],
#			     -command => sub { $zinc->Tk::focus(); },
			     -variable => \$itemtype)->grid(-row => 0,
							    -column => 1,
							    -sticky => 'w');

$rc->Button(-text => 'Add item',
	    -command => \&additem)->grid(-row => 0,
					 -column => 2,
					 -padx => 10,
					 -sticky => 'ew');
$rc->Button(-text => 'Add group',
	    -command => \&addgroup)->grid(-row => 0,
					  -column => 3,
					  -padx => 10,
					  -sticky => 'ew');
$rc->Button(-text => 'Remove',
	    -command => \&removeitem)->grid(-row => 0,
					    -column => 4,
					    -padx => 10,
					    -sticky => 'ew');

$rc->Checkbutton(-text => '-composescale',
		 -command => \&togglecomposescale,
		 -variable => \$composescale)->grid(-row => 0,
						    -column => 6,
						    -sticky => 'w');

$rc->Checkbutton(-text => '-composesrotation',
		 -command => \&togglecomposerot,
		 -variable => \$composerot)->grid(-row => 1,
						  -column => 6,
						  -sticky => 'w');


my $world = $zinc->add('group', $top);
$zinc->add('curve', $top, [0, 0, 80, 0],
	   -linewidth => 3,
	   -linecolor => $worldAxisColor,
	   -lastend => [6,8,3],
	   -tags => ["axis:$world"]);
$zinc->add('curve', $top, [0, 0, 0, 80],
	   -linewidth => 3,
	   -linecolor => $worldAxisColor,
	   -lastend => [6,8,3],
	   -tags => ["axis:$world"]);
$zinc->add('rectangle', $top, [-2, -2, 2, 2],
	   -filled => 1,
	   -fillcolor => $worldAxisColor,
	   -linecolor => $worldAxisColor,
	   -linewidth => 3,
	   -tags => ["axis:$world"]);
$zinc->add('text', $top,
	   -text => "This is the origin\nof the world",
	   -anchor => 's',
	   -color => $worldAxisColor,
	   -alignment => 'center',
	   -tags => ["axis:$world", 'text']);


$currentgroup = $world;

$zinc->Tk::bind('<1>', [\&mouseadd, 'item']);
$zinc->Tk::bind('<2>', [\&mouseadd, 'group']);
$zinc->Tk::bind('<Up>', \&moveup);
$zinc->Tk::bind('<Left>', \&moveleft);
$zinc->Tk::bind('<Right>', \&moveright);
$zinc->Tk::bind('<Down>', \&movedown);
$zinc->Tk::bind('<Next>', \&scaledown);
$zinc->Tk::bind('<Prior>', \&scaleup);
$zinc->Tk::bind('<Delete>', \&reset);
$zinc->Tk::bind('<Shift-Delete>', \&resetchildren);
$zinc->Tk::bind('<End>', \&rotateleft);
$zinc->Tk::bind('<Home>', \&rotateright);
$zinc->Tk::bind('<Insert>', \&swapaxis);

$zinc->Tk::bind('<Configure>', [\&resize]);

$zinc->Tk::focus();
$zinc->focusFollowsMouse();


MainLoop();

sub resize {
  my $ev = $zinc->XEvent();
  my $x = $ev->w/2;
  my $y = $ev->h/2;

  $zinc->treset($world);
  $zinc->treset("axis:$world");
  $zinc->translate($world, $x, $y);
  $zinc->translate("axis:$world", $x, $y);
}

sub swapaxis {
  if (defined($currentitem)) {
    $zinc->scale($currentitem, 1, -1);
    $zinc->scale("axisgrp:$currentitem", 1, -1);
  }
}

sub togglecomposerot {
  if (defined($currentitem)) {
    $zinc->itemconfigure($currentitem, -composerotation => $composerot);
    $zinc->itemconfigure("axisgrp:$currentitem", -composerotation => $composerot);
  }
}

sub togglecomposescale {
  my $bool;

  if (defined($currentitem)) {
    $zinc->itemconfigure($currentitem, -composescale => $composescale);
    $zinc->itemconfigure("axisgrp:$currentitem", -composescale => $composescale);
  }
}

sub dragitem {
  $drag = 1;
  return if (!defined($currentitem));

  my $ev = $zinc->XEvent();
  my $group = $zinc->group($currentitem);
  my ($x, $y) = $zinc->transform($group, [$ev->x, $ev->y]);

  $zinc->treset($currentitem);
  $zinc->treset("axisgrp:$currentitem");
  $zinc->translate($currentitem, $x, $y);
  $zinc->translate("axisgrp:$currentitem", $x, $y);
}

sub select {
  my @tags = $zinc->gettags('current');
  my $t;
  foreach $t (@tags) {
    if ($t =~ '^axis:(\d+)') {
      changeitem($1);
    }
  }
}

sub changeitem {
  my ($item) = @_;

  if (defined($currentitem) && !$drag) {
    $zinc->itemconfigure("axis:$currentitem && !text",
			 -linecolor => $inactiveAxisColor,
			 -fillcolor => $inactiveAxisColor);
    if ($currentitem != $currentgroup) {
      $zinc->itemconfigure("axis:$currentitem && !text",
			   -linewidth => 1);
    }
  }
  if (!defined($currentitem) || ($item != $currentitem)) {
    $zinc->itemconfigure("axis:$item && !text",
			 -linecolor => $activeAxisColor,
			 -fillcolor => $activeAxisColor,
			 -linewidth => 3);
    $currentitem = $item;
    $composerot = $zinc->itemcget($currentitem, -composerotation);
    $zinc->itemconfigure("axisgrp:$currentitem", -composerotation => $composerot);
    $composescale = $zinc->itemcget($currentitem, -composescale);
    $zinc->itemconfigure("axisgrp:$currentitem", -composescale => $composescale);
  }
  elsif (!$drag) {
    $currentitem = undef;
    $composerot = $composescale = 1;
  }
  $drag = 0;
}

sub selectgroup {
  my @tags = $zinc->gettags('current');
  my $t;
  foreach $t (@tags) {
    if ($t =~ '^axis:(\d+)') {
      changegroup($1);
    }
  }
}

sub changegroup {
  my ($grp) = @_;

  changeitem($grp);
  $zinc->itemconfigure("axis:$currentgroup && !text",
		       -linewidth => 1);
  if (defined($currentitem)) {
    $currentgroup = $currentitem;
  }
  else {
    $currentgroup = $world;
  }

  $zinc->itemconfigure("axis:$currentgroup && !text",
		       -linewidth => 3);
}

sub reset {
  if (defined($currentitem)) {
    $zinc->treset($currentitem);
    $zinc->treset("axisgrp:$currentitem");
  }
}

sub resetchildren {
  my @children;

  if (defined($currentitem) && ($zinc->type($currentitem) eq 'group')) {
    @children = $zinc->addtag('rt', 'withtag', 'all', $currentitem, 0);
    $zinc->treset('rt');
    $zinc->dtag('rt', 'rt');
  }
}

sub moveup {
  move(0, 20);
}

sub movedown {
  move(0, -20);
}

sub moveright {
  move(20, 0);
}

sub moveleft {
  move(-20, 0);
}

sub move {
  my ($dx, $dy) = @_;

  if (defined($currentitem)) {
    $zinc->translate($currentitem, $dx, $dy);
    $zinc->translate("axisgrp:$currentitem", $dx, $dy);
  }
}

sub scaleup {
  scale(1.1, 1.1);
}

sub scaledown {
  scale(0.9, 0.9);
}

sub scale {
  my ($dx, $dy) = @_;

  if (defined($currentitem)) {
    $zinc->scale($currentitem, $dx, $dy);
    $zinc->scale("axisgrp:$currentitem", $dx, $dy);
  }
}

sub rotateleft {
  rotate(-3.14159/18);
}

sub rotateright {
  rotate(3.14159/18);
}

sub rotate {
  my ($angle) = @_;

  if (defined($currentitem)) {
    $zinc->rotate($currentitem, $angle);
    $zinc->rotate("axisgrp:$currentitem", $angle);
  }
}

sub newrect {
  return $zinc->add('rectangle', $currentgroup,
		    [-15, -15, 15, 15],
		    -filled => 1,
		    -linewidth => 0,
		    -fillcolor => 'tan');
}

sub newarc {
  return $zinc->add('arc', $currentgroup,
		    [-25, -15, 25, 15],
		    -filled => 1,
		    -linewidth => 0,
		    -fillcolor => 'tan');
}

sub newcurve {
  return $zinc->add('curve', $currentgroup,
		    [-15, -15, -15, 15, 15, 15, 15, -15],
		    -filled => 1,
		    -linewidth => 0,
		    -fillcolor => 'tan');
}

sub newtext {
  my $item = $zinc->add('text', $currentgroup,
			-anchor => 's');
  $zinc->itemconfigure($item, -text => "Item id: $item");
  return $item;
}

sub newicon {
  my $item = $zinc->add('icon', $currentgroup,
			-image => $logo,
			-anchor => 'center');

  return $item;
}

sub newtriangles {
  my $item = $zinc->add('triangles', $currentgroup,
			[-25, 15, -10, -15, 5, 15,
			 20, -15, 35, 15, 50, -30],
			-colors => ['tan', 'wheat', 'tan', 'wheat']);
  return $item;
}

sub newtrack {
  my $labelformat = "x80x50+0+0 a0a0^0^0 a0a0^0>1 a0a0>2>1 x30a0>3>1 a0a0^0>2";

  my $item=$zinc->add('track', $currentgroup, 6,
		      -labelformat => $labelformat,
		      -speedvector => [30, -15],
		      -markersize => 20);
  $zinc->itemconfigure($item, 0,
		       -filled => 0,
		       -bordercolor => 'DarkGreen',
		       -border => 'contour');
  $zinc->itemconfigure($item, 1,
		       -filled => 1,
		       -backcolor => 'gray60',
		       -text => 'AFR6128');
  $zinc->itemconfigure($item, 2,
		       -filled => 0,
		       -backcolor => 'gray65',
		       -text => '390');
  $zinc->itemconfigure($item, 3,
		       -filled => 0,
		       -backcolor => 'gray65',
		       -text => '/');
  $zinc->itemconfigure($item, 4,
		       -filled => 0,
		       -backcolor => 'gray65',
		       -text => '350');
  $zinc->itemconfigure($item, 5,
		       -filled => 0,
		       -backcolor => 'gray65',
		       -text => 'TUR');
  return $item;
}

sub newwaypoint {
  my $labelformat = "a0a0+0+0 a0a0>0^1";

  my $item=$zinc->add('waypoint', $currentgroup, 2,
		      -labelformat => $labelformat);
  $zinc->itemconfigure($item, 0,
		       -filled => 1,
		       -backcolor => 'DarkGreen',
		       -text => 'TUR');
  $zinc->itemconfigure($item, 1,
		       -text => '>>>');
  return $item;
}

sub newtabular {
  my $labelformat = "f700f600+0+0 f700a0^0^0 f700a0^0>1 f700a0^0>2 f700a0^0>3 f700a0^0>4 f700a0^0>5";

  my $item=$zinc->add('tabular', $currentgroup, 7,
		      -labelformat => $labelformat);
  $zinc->itemconfigure($item, 0,
		       -filled => 1,
		       -border => 'contour',
		       -bordercolor => 'black',
		       -backcolor => 'gray60');
  $zinc->itemconfigure($item, 1,
		       -alignment => 'center',
		       -text => 'AFR6128');
  $zinc->itemconfigure($item, 2,
		       -alignment => 'center',
		       -text => '390');
  $zinc->itemconfigure($item, 3,
		       -alignment => 'center',
		       -text => '370');
  $zinc->itemconfigure($item, 4,
		       -alignment => 'center',
		       -text => '350');
  $zinc->itemconfigure($item, 5,
		       -alignment => 'center',
		       -text => '330');
  $zinc->itemconfigure($item, 6,
		       -alignment => 'center',
		       -text => 'TUR');
  return $item;
}

sub addaxes {
  my ($item, $length, $command, $infront) = @_;

  my $axesgroup = $zinc->add('group', $currentgroup,
			     -tags => ["axisgrp:$item"]);
  $zinc->add('curve', $axesgroup, [0, 0, $length, 0],
	     -linewidth => 2,
	     -lastend => [6,8,3],
	     -tags => ["axis:$item"]);
  $zinc->add('curve', $axesgroup, [0, 0, 0, $length],
	     -linewidth => 2,
	     -lastend => [6,8,3],
	     -tags => ["axis:$item"]);
  $zinc->add('rectangle', $axesgroup, [-2, -2, 2, 2],
	     -filled => 1,
	     -linewidth => 0,
	     -composescale => 0,
	     -tags => ["axis:$item"]);
  if ($infront) {
    $zinc->raise($item, $axesgroup);
  }
  $zinc->bind("axis:$item", '<B1-Motion>', \&dragitem);
  $zinc->bind("axis:$item", '<ButtonRelease-1>', $command);
}

sub additem {
  my $item;
  my $length = 25;
  my $itemontop = 0;

  if ($itemtype eq 'rectangle') {
    $item = newrect();
  }
  elsif ($itemtype eq 'arc') {
    $item = newarc();
  }
  elsif ($itemtype eq 'curve') {
    $item = newcurve();
  }
  elsif ($itemtype eq 'triangles') {
    $item = newtriangles();
  }
  elsif ($itemtype eq 'icon') {
    $item = newicon();
  }
  elsif ($itemtype eq 'text') {
    $item = newtext();
  }
  elsif ($itemtype eq 'track') {
    $item = newtrack();
    $itemontop = 1;
  }
  elsif ($itemtype eq 'waypoint') {
    $item = newwaypoint();
    $itemontop = 1;
  }
  elsif ($itemtype eq 'tabular') {
    $item = newtabular();
  }

  addaxes($item, 25, \&select, $itemontop);
  changeitem($item);
}

sub addgroup {
  my $item = $zinc->add('group', $currentgroup);

  addaxes($item, 80, \&selectgroup, 1);
  changegroup($item);
}

sub mouseadd {
  my ($w, $itemorgrp) = @_;
  my $ev = $zinc->XEvent();
  my ($x, $y) = $zinc->transform($currentgroup, [$ev->x, $ev->y]);
  my $item = $zinc->find('withtag', 'current');

  if (defined($item)) {
    my @tags = $zinc->gettags($item);
    foreach my $t (@tags) {
      return if ($t =~ '^axis');
    }
  }
  if ($itemorgrp eq 'group') {
    addgroup();
  }
  else {
    additem();
  }
  $zinc->translate($currentitem, $x, $y);
  $zinc->translate("axisgrp:$currentitem", $x, $y);
}

sub removeitem {
  if (defined($currentitem)) {
    $zinc->remove($currentitem, "axisgrp:$currentitem");
    if ($currentitem == $currentgroup) {
      $currentgroup = $world;
    }
    $currentitem = undef;
    $composescale = $composerot = 1;
  }
}
