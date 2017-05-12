#!/usr/bin/perl -w
# $Id: all_options.pl,v 1.5 2004/05/14 09:06:20 lecoanet Exp $
# This simple demo has been developped by C. Mertz <mertz@cena.fr>

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use Tk::Pane;

use strict;

my $mw = MainWindow->new();

# The explanation displayed when running this demo
my $label=$mw->Label(-text =>
"Click on one of the following
buttons to get a list of Item
attributes (or zinc options)
with their types.\n",
	   -justify => 'left')->pack(-padx => 10, -pady => 10);


# Creating the zinc widget
my $zinc = $mw->Zinc(-width => 1, -height => 1,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 0, -relief => 'sunken',
		     )->pack;

# Creating an instance of every item type
my %itemtypes;

# These Items have fields! So the number of fields must be given at creation time
foreach my $type qw(tabular track waypoint) {
    $itemtypes{$type} = $zinc->add($type, 1, 0);
}

# These items needs no specific initial values
foreach my $type qw(group icon map reticle text window) {
    $itemtypes{$type} = $zinc->add($type, 1);
}

# These items needs some coordinates at creation time
# However curves usually needs more than 2 points.
foreach my $type qw(arc curve rectangle) {
    $itemtypes{$type} = $zinc->add($type, 1, [0,0 , 1,1]);
}
# Triangles item needs at least 3 points for the coordinates 
foreach my $type qw(triangles) {
    $itemtypes{$type} = $zinc->add($type, 1, [0,0 , 1,1 , 2,2]);
}


sub showAllOptions {
    my ($type) = @_;

    my $tl = $mw->Toplevel;
    my $title = "All options of an item $type";
    my @options;
    if ($type eq 'zinc') {
	@options = $zinc->configure();
	$title = "All options of zinc widget";
    }
    else {
	@options = $zinc->itemconfigure($itemtypes{$type});
	$title = "All attributes of an item $type";
    }
    $tl->title($title);
    my $frame = $tl->Scrolled('Pane',
			      -scrollbars => 'e',
			      -height => 600,
			      );
    $frame->pack(-padx => 10, -pady => 10,
		 -ipadx => 10,
		 -fill => 'both',
		 -expand => 1,
		 );

    my $fm = $frame->LabFrame(-labelside => 'acrosstop',
			      -label => $title,
			      )->pack(-padx => 10, -pady => 10,
				      -ipadx => 10,
				      -fill => 'both');
    my $bgcolor = 'ivory';
    $fm->Label(-text => 'Option', -background => $bgcolor, -relief => 'ridge')
	->grid(-row => 1, -column => 1, -ipady => 10, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => ($type eq 'zinc') ? 'optionClass' : 'Type',
	       -background => $bgcolor, -relief => 'ridge')
	->grid(-row => 1, -column => 2, -ipady => 10, -ipadx => 5, -sticky => 'nswe');
    $fm->Label(-text => ($type eq 'zinc') ? 'defaultValue' : 'ReadOnly',
	       -background => $bgcolor, -relief => 'ridge')
	->grid(-row => 1, -column => 3, -ipady => 10, -ipadx => 5, -sticky => 'nswe');
    my $i = 2;
    my %options; #we used this hastable to sort the options by their names
    
    if ($type eq 'zinc') {
	for my $elem (@options) {
#	    print "$elem @$elem\n";
	    my ($optionName, $optionDatabaseName, $optionClass, $default, $optionValue) = @$elem;
	    $options{$optionName} = [$optionClass, $default, "", $optionValue];
	}
    }
    else {
	for my $elem (@options) {
	    my ($optionName, $optionType, $readOnly, $empty, $optionValue) = @$elem;
	    $options{$optionName} = [$optionType, $readOnly, $empty, $optionValue];
	}
    }
    for my $optionName (sort keys %options) {
	my ($optionType, $readOnly, $empty, $optionValue) = @{$options{$optionName}};
	$fm->Label(-text => $optionName, -relief => 'ridge')
	    ->grid(-row => $i, -column => 1, -ipady => 10, -ipadx => 5, -sticky => 'nswe');
	$fm->Label(-text => $optionType, -relief => 'ridge')
	    ->grid(-row => $i, -column => 2, -ipady => 10, -ipadx => 5, -sticky => 'nswe');

	# $empty is for provision by Zinc
	if ($type ne 'zinc') {
	    if ($readOnly) {$readOnly = "read only"} else { $readOnly = "" }
	}
	$fm->Label(-text => $readOnly, -relief => 'ridge')
	    ->grid(-row => $i, -column => 3, -ipady => 10, -ipadx => 5, -sticky => 'nswe');
	# we do not display $optionValue for these fake items
	$i++;
    }
    $tl->Button(-text => 'Close',
		-command => sub {$tl->destroy})->pack;    

}

my $col = $mw->Frame()->pack();

my $width=0;
foreach my $type (sort keys %itemtypes) {
    if (length ($type) > $width) {
	$width = length ($type);
    }
}

foreach my $type (sort keys %itemtypes) {
    $col->Button(-text => "$type",
		 -width => $width,
		 -command => sub {&showAllOptions ($type);},
		 )->pack(-pady => 4);	   
}
$col->Button(-text => "zinc widget options",
	     -command => sub {&showAllOptions ('zinc');},
	     )->pack(-pady => 4);	   

MainLoop();


1;
