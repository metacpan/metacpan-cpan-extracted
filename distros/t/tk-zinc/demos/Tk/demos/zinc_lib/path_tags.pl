#!/usr/bin/perl -w
# $Id: path_tags.pl,v 1.8 2003/10/14 09:01:52 mertz Exp $
# this pathtatg demo have been developped by C. Mertz mertz@cena.fr
# with the help of Daniel Etienne etienne@cena.fr

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;

#This demo only works with Tk::Zinc > "3.2.5b";

## this demo demonstrates the use of path tags to address one or more items
## belonging to a hierarchy of groups.
## This hierarchy is described just below, gr_xxx designates a group
## (with a tag xxx) and i_yyy designates an non-group item (with a tag yyy).

#  gr_top --- gr_a --- gr_aa --- gr_aaa --- gr_aaaa --- i_aaaaa
#          |       |         |          |-- i_aaab  |-- i_aaaab
#          |       |         -- i_aab
#          |       |-- i_ab
#          |       |
#          |       ---gr_ac --- i_aca
#          |                |
#          |-- i_b          --- i_acb
#          |
#          --- gr_c --- gr_ca --- i_caa
#                   |         |
#                   |         --- i_cab
#                   |-- i_cb
#                   |
#                   ---gr_cc --- i_cca
#                            |
#                            --- i_ccb
#the same objects are cloned and put in an other hierarchy where
#gr_top is replaced by gr_other_top

my $defaultForecolor = "grey80";
my $selectedColor = "yellow";
my $mw = MainWindow->new();

###########################################
# Text zone
###########################################

my $text = $mw->Text(-relief => 'sunken', -borderwidth => 2,
		     -height => 5, -font => "10x20");
$text->pack(-expand => 'yes', -fill => 'both');

$text->insert('0.0',
'This represents a group hierarchy:
  - groups are represented by a rectangle and an underlined title.
  - non-group items are represented by a text.
Select a pathTag or a tag with one of the radio-button
or experiment your own tags in the input field');

###########################################
# Zinc creation
###########################################

my $zinc = $mw->Zinc(-width => 850, -height => 360, -font => "10x20",
		     -borderwidth => 0, -backcolor => "black",
		     -forecolor => $defaultForecolor,
		     )->pack;

###########################################
# Creation of a bunch of radiobutton and a text input
###########################################

my $tagsfm = $mw->Frame()->pack();
my $pathtag;

my @pl = qw/-side left -expand 1 -padx .5c -pady .2c/;
my $left = $tagsfm->Frame->pack(@pl);
my $middle = $tagsfm->Frame->pack(@pl);
my $right = $tagsfm->Frame->pack(@pl);
my $rtop = $right->Frame->pack(-side => 'top');
my $rbottom = $right->Frame->pack(-side => 'top');
my $rbot_left = $rbottom->Frame->pack(-side => 'left');
my $rbot_right = $rbottom->Frame->pack(-side => 'left');

my $resultfm = $mw->Frame()->pack();
$resultfm->Label(-font => "10x20",
	     -relief => 'flat',
	     -text => 'explanation:',
	     )->pack(-side => 'left');
my $explan_txt = $resultfm->Label(-font => "10x20",
				  -relief => 'flat',
				  -width => 70,
				  -height => 3.5,
				  -text => '...',
				  -justify => 'left',
				  -wraplength => '16c',
				  )->pack(-side => 'left');


@pl = qw/-side top -pady 2 -anchor w/;
my @tags_explan;
@tags_explan = ("top" => "a simple tag for the top group",
		".top" => "all items in the root group with the tag 'top'",
		".top." => "direct children of a group in the root group with the tag 'top'",
		".top*" => "descendance of ONE group in the root group with the tag 'top'",
		".top*cca" => "items with a tag 'cca' in ONE direct group of root group with tag 'top'",
		".5." => "direct content of THE group with id 5");
while (@tags_explan) {
    my $tag = shift @tags_explan;
    my $explan = shift @tags_explan;
    $left->Radiobutton(-text     => $tag,
		       -font => "10x20",
		       -command => sub { &displayPathtag ($explan)},
		       -variable => \$pathtag,
		       -relief   => 'flat',
		       -value    => $tag,
		       )->pack(@pl);
}
@tags_explan = (".top*aa" => "items with a tag 'aa' in a direct group of root group with tag 'top'",
		".top*aa." => "direct children of ONE group with a tag 'aa', descending from a direct group of root group with tag 'top'",
		".top*aa*" => "descendance of ONE group with a tag 'aa', descending from a direct group of root group with tag 'top'",
		".top.a" => "items with a tag 'a' in a direct group of root group with tag 'top'",
		".top.a." => "direct children of ONE group with a tag 'a' in a direct group of root group with tag 'top'",
		".5*" => "descendance of THE group with id 5",
		);
while (@tags_explan) {
    my $tag = shift @tags_explan;
    my $explan = shift @tags_explan;
    $middle->Radiobutton(-text     => $tag,
			 -font => "10x20",
			 -command => sub { &displayPathtag ($explan)},
			 -variable => \$pathtag,
			 -relief   => 'flat',
			 -value    => $tag,
			 )->pack(@pl);
}


$rtop->Label(-font => "10x20",
	     -relief => 'flat',
	     -text => 'your own tag :',
	     )->pack(-side => 'left');
$rtop->Entry(-font => "10x20", -width => 15)
    ->pack(-side => 'left')->bind('<Key-Return>', sub {$pathtag = $_[0]->get();
						       &displayPathtag("sorry, I am not smart enough to explain your pathTag ;-)")});


@tags_explan =  (".top*aa*aaa" => "all items with a tag 'aaa' descending from ONE group with a tag 'aa' descending from ONE group with a tag 'top' child of the root group",
		 ".top*aa*aaa." => "children of ONE group with a tag 'aaa' descending from ONE group with a tag 'aa' descending from ONE group with a tag 'top' child of the root group",
		 ".top*aa*aaa*" => "descendance of ONE group with a tag 'aaa' descending from ONE group with a tag 'aa' descending from ONE group with a tag 'top' child of the root group",
		 ".other_top*aa*" => "descendance of ONE group with a tag 'aa' descending from ONE group with a tag 'other_top' child of the root group",
		 ".5*ca*" => "descendance of ONE group with a tag 'ca' descending from THE group with id 5",
		 );
while (@tags_explan) {
    my $tag = shift @tags_explan;
    my $explan = shift @tags_explan;
    $rbot_left->Radiobutton(-text     => $tag,
			    -font => "10x20",
			    -command => sub { &displayPathtag ($explan)},
			    -variable => \$pathtag,
			    -relief   => 'flat',
			    -value    => $tag,
			    )->pack(@pl);
}

@tags_explan = ("*aa*aaaa" => "all items with a tag 'aaaa' descending from a group with a tag 'aa'",
		"*aaa" => "all items with a tag 'aaa'",
		"aa || ca" => "items with tag 'aa' or tag 'ca'",
		"none" => "no items, as none has the tag 'none'",
		"all" => "all items",
		);
while (@tags_explan) {
    my $tag = shift @tags_explan;
    my $explan = shift @tags_explan;
    $rbot_right->Radiobutton(-text     => $tag,
			     -font => "10x20",
			     -command => sub { &displayPathtag ($explan)},
			     -command => \&displayPathtag,
			     -variable => \$pathtag,
			     -relief   => 'flat',
			     -value    => $tag,
			     )->pack(@pl);
}

# creating the item hierarchy
$zinc ->add('group', 1, -tags => ['top']);
&createSubHierarchy ('top');

# creating a parallel hierarchy
$zinc ->add('group', 1, -tags => ['other_top']);
&createSubHierarchy ('other_top');

### Here we create the genuine hierarchy of groups and items
### Later we will create graphical objects to display groups
sub createSubHierarchy {
    my ($gr) = @_;
    $zinc->add('group', $gr, -tags => ['a']);
    $zinc->add('text',  $gr, -tags => ['b', 'text'], -text => 'b',
	       -position => [270,150]);
    $zinc->add('group', $gr, -tags => ['c']);
    
    $zinc->add('group', 'a', -tags => ['aa']);
    $zinc->add('text',  'a', -tags => ['ab', 'text'], -text => 'ab'
	       , -position => [60,220]);
    $zinc->add('group', 'a', -tags => ['ac']);
    
    $zinc->add('group', 'aa', -tags => ['aaa']);
    $zinc->add('text',  'aa', -tags => ['aab', 'text'], -text => 'aab', 
	       -position => [90,190]);
    $zinc->add('group', 'aaa', -tags => ['aaaa']);
    $zinc->add('text',  'aaaa', -tags => ['aaaaa', 'text'], -text => 'aaaaa', 
	       -position => [150,110]);
    $zinc->add('text',  'aaaa', -tags => ['aaaab', 'text'], -text => 'aaaab',
	       -position => [150,130]);
    $zinc->add('text',  'aaa', -tags => ['aaab', 'text'], -text => 'aaab',
	       -position => [120,160]);
    
    $zinc->add('text', 'ac', -tags => ['aca'], -text => 'aca',
	       -position => [90,260]);
    $zinc->add('text',  'ac', -tags => ['acb', 'text'], -text => 'acb',
	       -position => [90,290]);
    
    $zinc->add('group', 'c', -tags => ['ca']);
    $zinc->add('text',  'c', -tags => ['cb', 'text'], -text => 'cb',
	       -position => [330,160]);
    $zinc->add('group', 'c', -tags => ['cc']);
    
    $zinc->add('text',  'ca', -tags => ['caa', 'text'], -text => 'caa',
	       -position => [360,110]);
    $zinc->add('text',  'ca', -tags => ['cab', 'text'], -text => 'cab',
	       -position => [360,130]);

    $zinc->add('text',  'cc', -tags => ['cca', 'text'], -text => 'cca',
	       -position => [360,200]);
    $zinc->add('text',  'cc', -tags => ['ccb', 'text'], -text => 'ccb',
	       -position => [360,220]);
}

## modifying the priority so that all rectangles and text will be visible
map { $_, $zinc->itemconfigure($_,-priority => 20)} ($zinc->find('withtype', 'text', ".top*"));
map { $_, $zinc->itemconfigure($_,-priority => 20)} ($zinc->find('withtype', 'text', ".other_top*"));
map { $_, $zinc->itemconfigure($_,-priority => 20)} ($zinc->find('withtype', 'group', ".top*"));
map { $_, $zinc->itemconfigure($_,-priority => 20)} ($zinc->find('withtype', 'group', ".other_top*"));

# converts a list of items ids in a list of sorted tags (the first tag of each item)
sub items2tags {
    my @items = @_;
    my @selected_tags;
    foreach my $item (@items) {
	my @tags = $zinc->itemcget ($item, -tags);
	next if $tags[0] =~ /frame|title/  ;    # to remove group titles frame
	push @selected_tags, $tags[0];
    }
    return sort @selected_tags;
}

### drawing :
####   a rectangle item for showing the bounding box of each group, 
###    a text item for the group name (i.e. its first tag)

## backgrounds used to fill rectangles representing groups
my @backgrounds = qw(grey25 grey35 grey43 grey50 grey55);

sub drawHierarchy {
    my ($group,$level) = @_;
    my @tags = $zinc->gettags($group);
#    print "level=$level (", $tags[0],")\n";
    foreach my $g ($zinc->find('withtype', 'group', ".$group.")) {
	&drawHierarchy ($g,$level+1);
    }
    my ($x,$y,$x2,$y2) = $zinc->bbox($group);
    $zinc->add('text',$group, -position => [$x-5,$y-4],
	       -text => $tags[0], -anchor => "w", -alignment => "left",
	       -underlined => 1,
	       -priority => 20,
	       -tags => ["title_".$tags[0], 'group_title'],
	       );
    ($x,$y,$x2,$y2) = $zinc->bbox($group);
    if (defined $x) {
	my $background  = $backgrounds[$level];
	$zinc->add('rectangle', $group, [$x+0,$y+5,$x2+5,$y2+2],
		   -filled => 1,
		   -fillcolor => $background,
		   -priority => $level,
		   -tags => ["frame_".$tags[0], 'group_frame'],
		   );
    } else {
	print "undefined bbox for $group : @tags\n";
    }
}

### this sub extracts out of groups both text and frame representing
### each group. This is necessary to avoid unexpected selection of
### rectangles and titles inside groups
sub extractTextAndFrames {
    foreach my $group_title ($zinc->find('withtag', 'group_title || group_frame')) {
	my @ancestors = $zinc->find('ancestor',$group_title);
#	print "$group_title, @ancestors\n";
	my $grandFather = $ancestors[1];
	$zinc->chggroup($group_title,$grandFather,1);
    }
}

## this sub modifies the color/line color of texts and rectangles
## representing selected items. 
sub displayPathtag {
#    print "var=@_ $pathtag\n";
    my $explanation = shift;
    my @selected = $zinc->find('withtag', $pathtag);
    my @tags = &items2tags(@selected);
#    print "selected: @tags\n";
    $explan_txt->configure(-text => $explanation ? "$explanation\n" : "");
	
    ## unselecting all items 
    foreach my $item ($zinc->find('withtype', 'text')) {
	$zinc->itemconfigure($item, -color => $defaultForecolor);
    }
    foreach my $item ($zinc->find('withtype', 'rectangle')) {
	$zinc->itemconfigure($item, -linecolor => $defaultForecolor);
    }

    ## highlighting selected items
    foreach my $item (@selected) {
	my $type = $zinc->type($item);
#	print $item, " ", $zinc->type($item), " ", join (",",$zinc->gettags($item)), "\n";
	if ($type eq 'text') {
	    $zinc->itemconfigure($item, -color => $selectedColor);
	} elsif ($type eq 'rectangle') {
	    $zinc->itemconfigure($item, -linecolor => $selectedColor);
	} elsif ($type eq 'group') {
	    my $tag = ($zinc->gettags($item))[0];
	    ## as there is 2 // hierachy, we must refine the tag used
	    ## to restrict to the proper hierarchy
	    ## NB: this is due to differences between the group hierarchy
	    ##     and the graphical object hierarchy used for this demo
	    if ($zinc->find('ancestors',$item,'top')) {
		$zinc->itemconfigure(".top*frame_$tag", -linecolor => $selectedColor);
		$zinc->itemconfigure(".top*title_$tag", -color => $selectedColor);
	    } elsif ($zinc->find('ancestors',$item,'other_top')) {
		$zinc->itemconfigure(".other_top*frame_$tag", -linecolor => $selectedColor);
		$zinc->itemconfigure(".other_top*title_$tag", -color => $selectedColor);
	    } else {
		$zinc->itemconfigure("frame_$tag", -linecolor => $selectedColor);
		$zinc->itemconfigure("title_$tag", -color => $selectedColor);
	    }
	}
    }
}

&drawHierarchy('top',0);
&drawHierarchy('other_top',0);
$zinc->translate('other_top', 400,0);
&extractTextAndFrames;



MainLoop;

