#!/usr/bin/perl
# $Id: atomic-groups.pl,v 1.3 2004/04/30 11:35:18 lecoanet Exp $
# this simple sample has been developped by C. Mertz mertz@cena.fr

package atomic_groups;

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use Tk::Checkbutton;
use Tk::Label;
use strict;

my $defaultfont = '-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*';
my $mw = MainWindow->new();
my $zinc = $mw->Zinc(-width => 500, -height => 350,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 0,
		     )->pack;


my $groups_group_atomicity = 0;
my $red_group_atomicity = 0;
my $green_group_atomicity = 0;

my $display_clipping_item_background = 0;
my $clip = 1;

$zinc->add('text', 1,
	   -font => $defaultfont,
	   -text =>
	   "- There are 3 groups: a red group containing 2 redish objects,\n".
	   "a green group containing 2 greenish objects,\n".
	   "and groups_group containing both previous groups.\n".
	   "- You can make some groups atomic or not by depressing \n".
	   "the toggle buttons at the bottom of the window\n".
	   "- Try and then click on some items to observe that callbacks\n".
	   " are then different: they modify either the item, or 2 items of\n".
           " a group or all items",
	   -anchor => 'nw',
	   -position => [10, 10]);


############### creating the top group with its bindings ###############################
my $groups_group = $zinc->add('group', 1, -visible => 1,
			      -atomic => $groups_group_atomicity,
			      -tags => [ 'groups_group' ]);

# the following callbacks will be called only if 'groups_group' IS atomic
$zinc->bind($groups_group, '<1>', \&modify_bitmap_bg);
$zinc->bind($groups_group, '<ButtonRelease-1>', \&modify_bitmap_bg);

############### creating the red_group, with its binding and its content ################
# the red_group may be atomic, that is is makes all children as a single object
# and sensitive to red_group callbacks
my $red_group = $zinc->add('group', $groups_group,
			   -visible => 1,
			   -atomic => $red_group_atomicity,
			   -sensitive => 1,
			   -tags => ['red_group'],
			   );
# the following callbacks will be called only if 'groups_group' IS NOT-atomic
# and if 'red_group' IS atomic
$zinc->bind($red_group, '<1>', sub { &modify_item_lines($red_group)} );
$zinc->bind($red_group, '<ButtonRelease-1>', sub { &modify_item_lines($red_group)} );


my $rc = $zinc->add('arc', $red_group,
		    [100, 200, 140, 240],
		    -filled => 1, -fillcolor => "red2",
		    -linewidth => 3, -linecolor => "white",
		    -tags => [ 'red_circle' ],
		    );

my $rr = $zinc->add('rectangle', $red_group,
		    [300, 200, 400,250],
		    -filled => 1, -fillcolor => "red2",
		    -linewidth => 3, -linecolor => "white",
		    -tags => [ 'red_rectangle' ],
		    );
# the following callbacks will be called only if 'groups_group' IS NOT atomic
# and if 'red_group' IS NOT atomic
$zinc->bind($rc, '<1>', \&toggle_color);
$zinc->bind($rc, '<ButtonRelease-1>', \&toggle_color);
$zinc->bind($rr, '<1>', \&toggle_color);
$zinc->bind($rr, '<ButtonRelease-1>', \&toggle_color);

############### creating the green_group, with its binding and its content ################
# the green_group may be atomic, that is is makes all children as a single object
# and sensitive to green_group callbacks
my $green_group = $zinc->add('group', $groups_group,
			     -visible => 1,
			     -atomic => $green_group_atomicity,
			     -sensitive => 1,
			     -tags => ['green_group'],
			    );
# the following callbacks will be called only if 'groups_group' IS NOT atomic
# and if 'green_group' IS atomic
$zinc->bind($green_group, '<1>', sub { &modify_item_lines($green_group) } );
$zinc->bind($green_group, '<ButtonRelease-1>', sub { &modify_item_lines($green_group) } );

my $gc = $zinc->add('arc', $green_group,
		    [100,270, 140,310],
		    -filled => 1, -fillcolor => "green2",
		    -linewidth => 3, -linecolor => "white",
		    -tags => [ 'green_circle' ],
		    );

my $gr = $zinc->add('rectangle', $green_group,
		    [300,270,  400,320],
		    -filled => 1, -fillcolor => "green2",
		    -linewidth => 3, -linecolor => "white",
		    -tags => [ 'green_rectangle' ],
		    );
# the following callbacks will be called only if 'groups_group' IS NOT atomic
# and if 'green_group' IS NOT atomic
$zinc->bind($gc, '<1>', \&toggle_color);
$zinc->bind($gc, '<ButtonRelease-1>', \&toggle_color);
$zinc->bind($gr, '<1>', \&toggle_color);
$zinc->bind($gr, '<ButtonRelease-1>', \&toggle_color);



my $current_bg = '';
###################### groups_group callback ##############
sub modify_bitmap_bg {
    if ($current_bg eq 'AlphaStipple2') {
	$current_bg = '';
    }
    else {
	$current_bg = 'AlphaStipple2';
    }
    foreach my $item ($rc, $rr, $gc, $gr) {
	$zinc->itemconfigure($item, -fillpattern => $current_bg);
    }
}

#################### red/green_group callback ##############
sub modify_item_lines {
    my ($gr) = @_;
    my @children = $zinc->find('withtag', ".$gr*"); # we are using a pathtag (still undocumented feature of 3.2.6) to get items of an atomic group!
    # we could also temporary modify the groups (make it un-atomic) to get its child

    my $current_linewidth = $zinc->itemcget($children[0], -linewidth);
    if ($current_linewidth == 3) {
	$current_linewidth = 0;
    }
    else {
	$current_linewidth = 3;
    }
    foreach my $item (@children) {
	$zinc->itemconfigure($item, -linewidth => $current_linewidth);
    }
	
}


##################### items callback ######################
sub toggle_color {
    my $item = $zinc->find('withtag', 'current');
    my $fillcolor = $zinc->itemcget($item, -fillcolor);
    my ($color,$num) = $fillcolor =~ /([a-z]+)(\d)/ ;
    if ($num == 2) {
	$num = 4;
    }
    else {
	$num = 2;
    }
    $zinc->itemconfigure($item, -fillcolor => "$color$num");
}


###################### toggle buttons at the bottom #######
my $row = $mw->Frame()->pack();
$row->Checkbutton(-text => 'groups_group is atomic',
		  -variable => \$groups_group_atomicity,
		  -command => sub { &atomic_or_not ($groups_group, \$groups_group_atomicity) },
		  )->pack(-anchor => 'w');	   

$row->Checkbutton(-text => 'red group is atomic   ',
		  -foreground => "red4",
		  -variable => \$red_group_atomicity,
		  -command => sub { &atomic_or_not ($red_group, \$red_group_atomicity) },
		  )->pack(-anchor => 'w');  

$row->Checkbutton(-text => 'green group is atomic ',
		  -foreground => "green4",
		  -variable => \$green_group_atomicity,
		  -command => sub { &atomic_or_not ($green_group, \$green_group_atomicity) },
		  )->pack(-anchor => 'w');
$row->Label()->pack(-anchor => 'w');
$row->Label(-text => "Following command \"\$zinc->find('overlapping', 0,200,500,400)\" returns:")->pack(-anchor => 'w');
my $label = $row->Label(-background => 'gray95')->pack(-anchor => 'w');


sub atomic_or_not {
    my ($gr,$ref_atomic) = @_;
    my $atomic = ${$ref_atomic};
    $zinc->itemconfigure( $gr, -atomic => $atomic);
    &update_found_items;
}

##### to update the list of enclosed items
sub update_found_items {
    $zinc->update;  # to be sure eveyrthing has been updated inside zinc!
    my @found = $zinc->find('overlapping', 0,200,500,400);
    my $str = "";
    foreach my $item (@found) {
	my @tags =   $zinc->itemcget($item, -tags);
	$str .= "  " . $tags[0];
    }
    $label->configure (-text => $str);
}

# to init the list of enclosed items
&update_found_items;

Tk::MainLoop;
