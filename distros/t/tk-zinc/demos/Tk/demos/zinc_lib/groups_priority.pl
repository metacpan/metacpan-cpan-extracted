#!/usr/bin/perl -w
# $Id: groups_priority.pl,v 1.5 2003/09/15 12:25:05 mertz Exp $
# This simple demo has been developped by C. Mertz <mertz@cena.fr>

package groups_priority;  # for avoiding symbol sharing between different demos

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;

use strict;

my $mw = MainWindow->new();

# The explanation displayed when running this demo
my $text = $mw->Text(-relief => 'sunken', -borderwidth => 2,
		     -height => 12);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
'There are two groups (a red one and a green one) each containing
 4 rectangles. Those rectangles display their current priority.
The following operations are possible:
   "Mouse Button 1" for dragging objects.
   "Mouse Button 2" for dragging a colored group.
   "Key +" on a rectangle to raise it inside its group.
   "Key -" on a rectangle to lower it inside its group.
   "Key l" on a rectangle to lower its colored group.
   "Key r" on a rectangle to raise its colored group.
   "Key t" on a rectangle to change its group (but not its color!).
   "Key [0-9] on a rectangle to set the priority to [0-9]
Raising or lowering an item inside a group modify its priority if necessary');

# Creating the zinc widget
my $zinc = $mw->Zinc(-width => 600, -height => 500,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 3, -relief => 'sunken',
		     )->pack;

#########################################################################"
# Creating the redish group
my $group1 = $zinc->add('group', 1, -visible => 1);

my $counter=0;
# Adding 4 rectangles with text to redish group
foreach my $data ( [200,100, 'red'], [210,210,'red1'],
		   [390,110,'red2'], [395,215,'red3'] ) {
    $counter += 2;
    my ($centerx,$centery,$color) = @{$data};
    # this small group is for merging together :
    #   the rectangle and the text showing its name
    my $g = $zinc->add('group', $group1,
		       -visible => 1,
		       -atomic => 1,
		       -sensitive => 1,
		       -priority => $counter,
		       );
    my $rec = $zinc->add('rectangle', $g, [$centerx-100,$centery-60,
					   $centerx+100, $centery+60],
			  -fillcolor => $color, -filled => 1,
			  );
    my $txt = $zinc->add('text', $g,
			 -position => [$centerx,$centery],
			 -text => "pri=$counter",
			 -anchor => 'center',
			 );
    # Some bindings for dragging the rectangle or the full group
    $zinc->bind($g, '<ButtonPress-1>' => [\&press, $g, \&motion]);
    $zinc->bind($g, '<ButtonRelease-1>' => \&release);
    $zinc->bind($g, '<ButtonPress-2>' => [\&press, $g, \&groupMotion]);
    $zinc->bind($g, '<ButtonRelease-2>' => \&release);
}

#########################################################################"
# Creating the greenish group
my $group2 = $zinc->add('group', 1, -visible => 1);
$counter=0;

# Adding 4 rectangles with text to greenish group
foreach my $data ( [200,300,'green1'], [210,410,'green2'],
		   [390,310,'green3'], [395,415,'green4'] ) {
    $counter++;
    my ($centerx,$centery,$color) = @{$data};
    # this small group is for merging together a rectangle
    # and the text showing its priority
    my $g = $zinc->add('group', $group2,
		       -atomic => 1,
		       -sensitive => 1,
		       -priority => $counter,
		       );
    my $rec = $zinc->add('rectangle', $g, [$centerx-100,$centery-60,
					   $centerx+100, $centery+60],
			  -fillcolor => $color, -filled => 1,
			  );
    my $txt = $zinc->add('text', $g,
			 -position => [$centerx,$centery],
			 -text => "pri=$counter",
			 -anchor => 'center',
			 );
    # Some bindings for dragging the rectangle or the full group
    $zinc->bind($g, '<ButtonPress-1>' => [\&press, $g, \&motion]);
    $zinc->bind($g, '<ButtonRelease-1>' => \&release);
    $zinc->bind($g, '<ButtonPress-2>' => [\&press, $g, \&groupMotion]);
    $zinc->bind($g, '<ButtonRelease-2>' => \&release);
}


#########################################################################"
# adding the key bindings

# the focus on the widget is ABSOLUTELY necessary for key bindings!
$zinc->Tk::focus(); 

$zinc->Tk::bind('<KeyPress-r>' => \&raiseGroup);
$zinc->Tk::bind('<KeyPress-l>' => \&lowerGroup);
$zinc->Tk::bind('<KeyPress-plus>' => \&raise);
$zinc->Tk::bind('<KeyPress-KP_Add>' => \&raise);
$zinc->Tk::bind('<KeyPress-minus>' => \&lower);
$zinc->Tk::bind('<KeyPress-KP_Subtract>' => \&lower);
$zinc->Tk::bind('<KeyPress-t>' => \&toggleItemGroup);

my @KP_MAPPINGS = qw (Insert End Down Next Left Begin Right Home Up Prior);

for my $i (0..9) {
    $zinc->Tk::bind("<KeyPress-$i>" => [\&setPriorrity, $i]);
    my $code = $KP_MAPPINGS[$i];
    $zinc->Tk::bind("<KeyPress-KP_$code>" => [\&setPriorrity, $i]);
}

# The following binding is currently not possible; only text items
# with focus can get a KeyPress or KeyRelease event
#    $zinc->bind($g, '<KeyPress>' => [\&raise, $g]);

#########################################################################"
# Definition of all callbacks

sub updateLabel {
    my ($group) = @_;
    my $priority = $zinc->itemcget($group, -priority);
    # we get the text item from this group:
    my $textitem = $zinc->find('withtype', 'text', ".$group.");
    $zinc->itemconfigure($textitem, -text => "pri=$priority");
}

sub setPriorrity {
    my ($zinc, $priority) = @_;
    my $item = $zinc->find('withtag', 'current');
    return unless $item;
    $zinc->itemconfigure ($item, -priority => $priority);
    &updateLabel($item);
}
    

# Callback to lower a small group of a rectangle and a text
sub lower {
    my ($zinc) = @_;
    # to get the item under the cursor!
    my $item = $zinc->find('withtag', 'current');
    return unless $item;
    $zinc->lower($item);
    &updateLabel($item);
}

# Callback to raise a small group of a rectangle and a text
sub raise {
    my ($zinc) = @_;
    # to get the item under the cursor!
    my $item = $zinc->find('withtag', 'current');
    return unless $item;
    $zinc->raise($item);
    &updateLabel($item);
}

# Callback to raise the group of groups of a rectangle and a text
sub lowerGroup {
    my ($zinc) = @_;
    # to get the item under the cursor!
    my $item = $zinc->find('withtag', 'current');
    return unless $item;
    my $coloredGroup = $zinc->group($item);
    $zinc->lower($coloredGroup);
}

# Callback to raise the group of groups of a rectangle and a text
sub raiseGroup {
    my ($zinc) = @_;
    # to get the item under the cursor!
    my $item = $zinc->find('withtag', 'current');
    return unless $item;
    my $coloredGroup = $zinc->group($item);
    $zinc->raise($coloredGroup);
    &updateLabel($item);
}

# Callback to change the group of groups of a rectangle and a text
sub toggleItemGroup {
    my ($zinc) = @_;
    # to get the item under the cursor!
    my $item = $zinc->find('withtag', 'current');
    return unless $item;
    my $newgroup;
    if ($group1 == $zinc->group($item)) {
	$newgroup = $group2;
    }
    else {
	$newgroup = $group1;
    }
    
    $zinc->chggroup($item,$newgroup,1); ## the lats argument is true for mainting $item' position
    &updateLabel($item);
}

# callback for starting a drag
my ($x_orig, $y_orig);
sub press {
    my ($zinc, $group, $action) = @_;
    my $ev = $zinc->XEvent();
    $x_orig = $ev->x;
    $y_orig = $ev->y;
    $zinc->Tk::bind('<Motion>', [$action, $group]);
}

# Callback for moving a small group of a rectangle and a text
sub motion {
    my ($zinc, $group) = @_;
    my $ev = $zinc->XEvent();
    my $x = $ev->x;
    my $y = $ev->y;

    $zinc->translate($group, $x-$x_orig, $y-$y_orig);
    $x_orig = $x;
    $y_orig = $y;
}

# Callback for moving a group of groups of a rectangle and a text
sub groupMotion {
    my ($zinc, $group) = @_;
    my $ev = $zinc->XEvent();
    my $x = $ev->x;
    my $y = $ev->y;

    my $coloredGroup = $zinc->group($group);
    $zinc->translate($coloredGroup, $x-$x_orig, $y-$y_orig);
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
