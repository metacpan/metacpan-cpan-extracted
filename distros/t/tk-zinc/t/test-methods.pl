#!/usr/bin/perl -w
# $Id: test-methods.pl,v 1.5 2003/09/11 10:03:05 mertz Exp $
# This non-regression test has been developped by C. Mertz <mertz@cena.fr>

use Tk;
use Tk::Zinc;
use Getopt::Long;
use TestLog;

use strict;

use constant ERROR => '--an error--';


# the following list be coherent with the treatments done in the TEST section.
my @testsList = (
		 1 => 'test_contour_and_coords (quick)',
		 2 => 'test_forbidden_operations_on_root_group (quick)',
		 3 => 'test_errors (quick)',
		 4 => 'test_bboxes (quick)',
		 5 => 'test_gradient_coding (quick)',
		 );
my %testsHash;
{ my @tests = @testsList;
  while (@tests) {
      my $num = shift (@tests);
      my $comment = shift (@tests);
      $testsHash{ $num } = $comment;
  }
}

unshift (@INC, "/usr/lib/perl5/Tk");  # for getting Tk some images;

# les variables positionnées en fonction des options de la ligne de commande
my $opt_log = 0;
my $opt_trace = "";
my $opt_render = -1;
my $opt_type = 0;
my $outfile;
my $opt_tests = "all";

# on récupère les options
Getopt::Long::Configure('pass_through');
my $optstatus = GetOptions('log=i' => \$opt_log,
			   'out=s' => \$outfile,
			   'trace=s' => \$opt_trace,
			   'render:s' => \$opt_render,
			   'type=s' => \$opt_type,
			   'help' => \&usage,
			   'tests:s' => \$opt_tests,
			   );

# on teste la validité de l'option -render!
if ($opt_render eq '') {
    print "-render option have no value!\n";
    &usage;
}
$opt_render = 1 if $opt_render == -1;
unless ($opt_render==0 or $opt_render==1 or $opt_render==2) {
    print "-render option value must be 0, 1 or 2!\n";
    &usage;
}


$outfile = "methods-$Tk::Zinc::VERSION.log" if (!defined $outfile);

&openLog($outfile, $opt_log);

sub usage {
    my ($text) = @_;
    print $text,"\n" if (defined $text);
    print "test-methods [options]\n";
    print "       A non-regression test suite for zinc.\n";
    print "       Some exhaustive test of TkZinc methods. Of course everything is not tested yet\n";
    print " options are:\n";
    print " -help           to print this short help\n";
    print " -log <n>        trace level, defaulted to 0; higher level trace more infos\n";
    print " -out filename   the log filename. defaulted to methods-<version><-rendering>.log\n";
    print "      NB: the previous log file is always renamed with a .prev suffix\n";
    print " -render 0|1|2   to select the render option of TkZinc (defaulted to 1)\n";
    print " -trace <an_item_option>  to better trace usage of an option\n";
    print " -type <a_zinc_item_type> to limits tests to this item type.\n";
    print " -tests to get the list of available tests.\n";
    print " -tests i,j,k... to define the list of tests to pass.\n";
    exit;
}

my $mw = MainWindow->new();

&log (0, "testing Zinc-perl Version=" . $Tk::Zinc::VERSION . " - ", $mw->zinc(), "\n");

## must be done after the LOG file is open
my @tests = &parseTestsOpt($opt_tests);
my %tests;
foreach my $t (@tests) {$tests{$t} = $t }


# The explanation displayed when running this demo
my $label=$mw->Label(-text => "This is a non-regression test, testing
some sets of methods!",
		     -justify => 'left')->pack(-padx => 10, -pady => 10);


# Creating the zinc widget
my $zinc = $mw->Zinc(-width => 500, -height => 500,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 0, -relief => 'sunken',
		     -render => $opt_render,
		     )->pack;

&setZincLog($zinc);

sub test_gradient_coding {
    &log (0, "#----  Start of test_gradient_coding ----\n");
    my $log_level = 2 ;
    ### CM to be done!

    ### first testing legal gradient
    foreach (0..2) {
	my $i=0;
	foreach my $g ("red", "bLue","#ff00ff","rgb:12/34/56","CIEXYZ:1.2/0.9/3.4",
		       "CIEuvY:0.5/.4/0.9", "CIExyY:.52/0.1/0.8", "CIELab:99.1/43./56.1",
		       "CIELuv:88/-1/-2.1", "TekHVC:345/1.2/100",
		       ) {
	    ## first simple color, with different X legal coding
	    &test_eval ($log_level, "gname", $g,"grad".$i);
	    $i++;
	    ## the same color with transparency
	    my $transparency = ($i * 4) % 101;
	    &test_eval ($log_level, "gname", "$g;$transparency","grad".$i);
	    $i++;	
	}

	## different axial gradient without the gradient type at the beginning
	foreach my $g ("red|blue", "red |blue", "red | blue",
		       "red|green|blue", "red |green|blue", "red |green |blue", "red | green|blue"
		       , "red |green| blue", "red |green | blue", "red | green | blue") {
	    ## first simple color, with different X legal coding
	    &test_eval ($log_level, "gname", $g,"grad".$i);
	    $i++;
	}
	## different axial gradient with explicit gradient type at the beginning
	## and different angle value!
	foreach my $angle qw(0 12 90 271 360) {
	    foreach my $g ("=axial $angle |red|blue",
			   "=axial $angle | red|blue",
			   "=axial $angle | red |blue",
			   "=axial $angle | red | blue",
			   "=axial $angle | red|green|blue",
			   "=axial $angle |red |green|blue",
			   "=axial $angle |red |green |blue",
			   "=axial $angle |red | green|blue",
			   "red |green| blue",
			   "red |green | blue",
			   "red | green | blue",
			   ) {
		## first simple color, with different X legal coding
		&test_eval ($log_level, "gname", $g,"grad".$i);
		$i++;
	    }
	}
	# and now deleting unused named gradient
	foreach my $j (0..$i-1) {
	    &test_eval ($log_level, "gdelete", "grad".$j);
	}
    }

    ### and now testing illegal gradient
    my $i=-1;
    &test_no_eval ("X color name with blank inside",
		   $log_level, "gname", "navy blue","grad".$i++);
    &test_no_eval ("bad gradient type",
		   $log_level, "gname", "=badtype 1 |red|blue","grad".$i++);
    &test_no_eval ("axial gradient with excessive parameters",
		   $log_level, "gname", "=axial 67 1 |red|blue","grad".$i++);
    &test_no_eval ("radial gradient with excessive parameters",
		   $log_level, "gname", "=radial 30 32 1 |red|blue","grad".$i++);
    &test_no_eval ("path gradient with excessive parameters",
		   $log_level, "gname", "=path 30 32 1 |red|blue","grad".$i++);
    ## testing bad types for gradient type
    # to be done
    foreach my $j (0..$i-1) {
	&test_eval ($log_level, "gdelete", "grad".$j);
    }
    
    &log (0, "#----  End of test_gradient_coding  -----\n");
} # end of test_gradient_coding
    
## TkZinc bbox method doesn't return correct values for bbox. This test
# function tries to find out in which cases these bbox are wrong
sub test_bboxes {
    &log (0, "#----  Start of test_bboxes ----\n");
    &creating_items; # to know exactly which items exists at the beginning of this test

    # Rectangles
    &bbox_must_be($zinc->add('rectangle', 1, [100,200,300,400]),
		  [100,200,300,400], "a simple rectangle");
    &bbox_must_be($zinc->add('rectangle', 1, [300,400,100,200]),
		  [100,200,300,400], "a simple reversed rectangle");
    
    # Rectangles with linewidth = 2, 3, 4 and 5
    &bbox_must_be($zinc->add('rectangle', 1, [100,200,300,400], -linewidth =>2),
		  [100,200,300,400], "a simple rectangle with linewidth of 2");
    &bbox_must_be($zinc->add('rectangle', 1, [100,200,300,400], -linewidth =>3),
		  [100,200,300,400], "a simple rectangle with linewidth of 3");
    &bbox_must_be($zinc->add('rectangle', 1, [100,200,300,400], -linewidth =>4),
		  [100,200,300,400], "a simple rectangle with linewidth of 4");
    &bbox_must_be($zinc->add('rectangle', 1, [100,200,300,400], -linewidth =>5),
		  [100,200,300,400], "a simple rectangle with linewidth of 5");
    
    # Rectangular curves
    &bbox_must_be($zinc->add('curve', 1, [ [100,200], [300,200], [300,400], [100,400] ],
			     -linewidth =>0),
		  [100,200,300,400], "a rectangular curve of linewidth => 0");
    &bbox_must_be($zinc->add('curve', 1, [ [100,200], [300,200], [300,400], [100,400] ]),
		  [100,200,300,400], "a rectangular curve of linewidth => 1");
    &bbox_must_be($zinc->add('curve', 1, [ [100,200], [300,200], [300,400], [100,400] ],
			     -linewidth => 2),
		  [100,200,300,400], "a rectangular curve of linewidth => 2");
    &bbox_must_be($zinc->add('curve', 1, [ [100,200], [300,200], [300,400], [100,400] ],
			     -linewidth => 3),
		  [100,200,300,400], "a rectangular curve of linewidth => 3");
    &bbox_must_be($zinc->add('curve', 1, [ [100,200], [300,200], [300,400], [100,400] ],
			     -linewidth => 5),
		  [100,200,300,400], "a rectangular curve");

    # triangular curves (with a sharp angle)
    &bbox_must_be($zinc->add('curve', 1, [ [0,0], [100,0], [0,10] ]),
		  [0,0,100,10], "a triangular curve of linewidth => 1)");

    # Arcs
    &bbox_must_be($zinc->add('arc', 1, [100,200,300,400]),
		  [100,200,300,400], "an arc");
    &bbox_must_be($zinc->add('arc', 1, [100,200,300,400], -linewidth => 2),
		  [100,200,300,400], "an arc of linewidth => 2");
    &bbox_must_be($zinc->add('arc', 1, [100,200,300,400], -linewidth => 3),
		  [100,200,300,400], "an arc of linewidth => 3");
    

    &log (0, "#----  End of test_bboxes  -----\n");
} # end of test_bboxes

sub bbox_must_be {
    my ($item, $bbox_ref, $explanation) = @_;
    my @computed_bbox=$zinc->bbox($item);
    my @theoritical_bbox = @{$bbox_ref};
    unless (&equal_flat_arrays (\@theoritical_bbox, \@computed_bbox)) {
	&log(-10, "bad bbox of $explanation:\n  ## computed = ", &printableArray(\@computed_bbox),
	     " theoritical = ", &printableArray(\@theoritical_bbox), "\n");
    }
} # end of bbox_must_be


sub test_contour_and_coords {
    &log (0, "#----  Start of test_contour_and_coords ----\n");
    my $log_level = 2 ;

    $zinc->add('rectangle', 1, [ [100,200], [400,300] ], -tags => ['rect1']);
    my $contour_rect = [ [100,200], [100,300], [400,300], [400,200] ];
    my $rev_contour_rect = [ [100,200], [400,200], [400,300], [100,300] ];

    $zinc->add('rectangle', 1, [ 100,200, 400,300 ], -tags => ['rect2']);
    &verify_coords_of_contour ('eq','rect1', 'rect2', 0);
    &verify_coords_of_contour_points ('eq','rect1', 'rect2', 0);


    $zinc->add('arc', 1, [ [100,200], [400,300] ], -tags => ['arc1']);
    $zinc->add('arc', 1, [ 100,200, 400,300 ], -tags => ['arc2']);
    &verify_coords_of_contour ('eq','arc1', 'arc2', 0);
    &verify_coords_of_contour_points ('eq','arc1', 'arc2', 0);

    my $contour1 = [ [100,200], [400,300,'c'], [500,100], [350,10, 'c'], [300,500,'c'], [50,100] ];
    my $contour2 = [  100,200,   400,300,       500,100,   350,10,        300,500,       50,100 ];
    my $contour3 = [ [100,200], [400,300],     [500,100], [350,10],      [300,500],     [50,100]];
    $zinc->add('curve', 1, $contour1, -tags => ['curve1']);
    $zinc->add('curve', 1, $contour2, -tags => ['curve2']);
    $zinc->add('curve', 1, $contour3, -tags => ['curve3']);
    &verify_coords_of_contour ('ne','curve1', 'curve2', 0);
    &verify_coords_of_contour_points ('ne','curve1', 'curve2', 0);
    
    &verify_coords_of_contour ('eq','curve2', 'curve3', 0);
    &verify_coords_of_contour_points ('ne','curve2', 'curve3', 0);

    ## testing contours
    $zinc->add('curve', 1, [], -tags => ['curve_contour_0']);
    $zinc->add('curve', 1, [], -tags => ['curve_contour_plus']);
    $zinc->add('curve', 1, [], -tags => ['curve_contour_minus']);
    $zinc->contour('curve_contour_0','add',0, $contour1);
    $zinc->contour('curve_contour_plus','add',+1, $contour1);
    $zinc->contour('curve_contour_minus','add',-1, $contour1);
    &verify_coords_of_contour ('eq','curve1', 'curve_contour_0', 0);
    &verify_coords_of_contour ('ne','curve_contour_plus', 'curve_contour_minus', 0);
    if (&nequal_cplx_arrays ($zinc->coords('curve_contour_0',0),
			     $zinc->coords('curve_contour_minus',0))) {
	&verify_coords_of_contour ('eq','curve1', 'curve_contour_plus', 0);
    } else {
	&verify_coords_of_contour ('eq','curve1', 'curve_contour_minus', 0);
    }
    $zinc->add('curve', 1, [], -tags => ['curve_contour_minus_plus']);
    $zinc->contour('curve_contour_minus_plus','add',1,
		   [$zinc->coords('curve_contour_minus',0)]);
    &verify_coords_of_contour ('eq','curve1', 'curve_contour_minus_plus', 0);

    ## the following curves are similar, because the first contour is
    ## always set counterclockwise
    $zinc->add('curve', 1, $contour_rect, -tags => ['curve_rect_coords']);
    $zinc->add('curve', 1, $rev_contour_rect, -tags => ['curve_rect_coords_reversed']);
    &verify_coords_of_contour ('ne','curve_rect_coords', 'curve_rect_coords_reversed', 0); # we should test they are reversed
    
    $zinc->add('curve', 1, [], -tags => ['curve_rect_0']);
    $zinc->add('curve', 1, [], -tags => ['curve_rect_plus']);
    $zinc->add('curve', 1, [], -tags => ['curve_rect_minus']);

    ## the following lines are errors: we cannot add an item as contour with flag 0
    &test_no_eval ("adding a contour from a rectangle with flag=0",
		   $log_level, "contour", 'curve_rect_0','add',0, 'rect1');
    &test_no_eval ("adding a contour from an arc with flag=0",
		   $log_level, "contour", 'curve_rect_0','add',0, 'arc1');
    
    $zinc->contour('curve_rect_plus','add',1, 'rect1');
    $zinc->contour('curve_rect_minus','add',-1, 'rect1');
    &verify_coords_of_contour ('ne','curve_rect_plus', 'curve_rect_minus', 0);
    &verify_coords_of_contour ('eq','curve_rect_coords', 'curve_rect_plus', 0);
    &verify_coords_of_contour ('eq','curve_rect_coords_reversed', 'curve_rect_minus', 0);

    $zinc->add('tabular',1, 2, -tags => ['tabular1']);
    $zinc->add('track',1, 2, -tags => ['track1']);
    $zinc->add('waypoint',1, 2, -tags => ['waypoint1']);
    $zinc->add('reticle',1, -tags => ['reticle1']);

    ## we test now the following errors: we cannot use a track, waypoint, reticle, map as a contour
    &test_eval ($log_level, "contour", 'curve_rect_0','add',1, 'tabular1');
    &test_no_eval ("using the contour of a track",
		   $log_level, "contour", 'curve_rect_0','add',1, 'track1');
    &test_no_eval ("using the contour of a waypoint",
		   $log_level, "contour", 'curve_rect_0','add',1, 'waypoint1');
    &test_no_eval ("using the contour of a reticle",
		   $log_level, "contour", 'curve_rect_0','add',1, 'reticle1');

    ## we test now the following errors: we cannot add a contour to track, waypoint, rectangle...
    &test_no_eval ("adding a contour to a track",
		   $log_level, "contour", 'track1','add',1, 'rect1');
    &test_no_eval ("adding a contour to a waypoint",
		   $log_level, "contour", 'waypoint1','add',1, 'rect1');
    &test_no_eval ("adding a contour to a rectangle",
		   $log_level, "contour", 'rect1','add',1, 'rect2');

    &test_no_eval ("adding a contour with a malformed list",
		   $log_level, "contour", 'curve_rect_0','add',1, [1]);
    &test_no_eval ("adding a contour with a malformed list",
		   $log_level, "contour", 'curve_rect_0','add',1, [1, 2, 3]);
    &test_no_eval ("adding a contour with a malformed list",
		   $log_level, "contour", 'curve_rect_0','add',1, [1, 2, 'c']);
    &test_no_eval ("adding a contour with a malformed list",
		   $log_level, "contour", 'curve_rect_0','add',1, [1, 2, [3, 4] ]);
    &test_no_eval ("adding a contour with a malformed list",
		   $log_level, "contour", 'curve_rect_0','add',1, [1, 2, [3, 4], [5, 6] ]);

    # we should test here what happens when successive points are identical in a curve

    # we should test here what happens when the last point is identical to the first point in a curve
    
    &log (0, "#----  End of test_contour_and_coords  -----\n");
} # end of test_contour_and_coords



sub test_forbidden_operations_on_root_group {
    &log (0, "#----  Start of test_forbidden_operations_on_root_group ----\n");
    my $log_level = 2 ;

    my @all_items =  $zinc->find('withtag',".1*");
    print "Items before deleting 1: @all_items\n";
    &test_no_eval ("removing the root group",
		   $log_level, "remove", 1); ## cannot delete root group
    @all_items =  $zinc->find('withtag',".1*");
    print "Items after deleting 1: @all_items\n";
    $zinc->add('group', 1, -tags => "g2");
    # cannot chggroup root group:    
    &test_no_eval ("changing the group of the root group",
		   $log_level, "chggroup", 1,"g2");
    # cannot clone root group
    &test_no_eval ("cloning the root group",
		   $log_level, "clone", 1);
    
    &log (0, "#----  End of test_forbidden_operations_on_root_group  -----\n");
} # end of test_forbidden_operations_on_root_group


### tests all errors as defined in the refman
sub test_errors {
    &log (0, "#----  Start of test_errors ----\n");
    my $log_level = 2 ;

    &creating_items;

    ## add method with bad argument
    # In a curve, it is an error to have more than two succcessive control points
    # or to start or finish a curve with a control point.
    &test_no_eval ("having more than two succcessive control points",
		   $log_level, "add", 'curve', 1,
		   [ [10,20], [30,40,'c'], [50,60,'c'], [70,80,'c'], [90,100] ]);
    &test_no_eval ("starting a curve with a control point",
		   $log_level, "add", 'curve', 1,
		   [ [30,40,'c'], [50,60], [70,80], [90,100] ]);
    &test_no_eval ("finishing a curve with a control point",
		   $log_level, "add", 'curve', 1,
		   [ [30,40,], [50,60,'c'], [70,80], [90,100,'c'] ]);
    
    # Text indices
    # sel.first Refers to the first character of the selection in the item.
    # If the selection is not in the item, this form returns an error.
     &test_no_eval ("refering to sel.first in a text item without selection",
		   $log_level, "insert", 'text', 'sel.first', "string");
    # sel.last Refers to the last character of the selection in the item.
    # If the selection is not in the item, this form returns an error.
     &test_no_eval ("refering to sel.last in a text item without selection",
		   $log_level, "insert", 'text', 'sel.last', "string");
 
    # If no item is named by tagOrId or if the item doesn t support anchors,
    # an error is raised.
    &test_no_eval ("refering no item by tagOrId with anchorxy",
		   $log_level, "anchorxy", 'bad_tag', 'rectangle');

    # If the item doesn't support anchors, an error is raised.
    &test_no_eval ("refering item that does not support anchors",
		   $log_level, "anchorxy", 'rectangle', 'ne');

    # If the item doesn't support anchors, an error is raised.
    &test_no_eval ("refering a bad anchor name",
		   $log_level, "anchorxy", 'text', 'not_an_anchor');

#    If the command parameter is omitted, bind returns the command associated
#    with tagOrId and sequence or an error is raised if there is no such binding.
    &test_no_eval ("refering a non-existing bindind with bind",
		   $log_level, "bind", 'text', 'badseq');

#    $zinc->contour(tagOrId, operatorAndFlag, coordListOrTagOrId);
    # An error is generated if items are not of a correct type or if the
    # coordinate list is malformed.
    # tested in &test_contour_and_coords
    
#    If no items are named by tagOrId, an error is raised.
    &test_no_eval ("refering a non-existing item with hasanchors",
		   $log_level, "hasanchors", 'badtag');

#    If no items are named by tagOrId, an error is raised.
    &test_no_eval ("refering a non-existing item with hasfields",
		   $log_level, "hasfields", 'badtag');

    # If no items are named by tagOrId, an error is raised.
    &test_no_eval ("refering a non-existing item with hastag",
		   $log_level, "hastag", 'badtag', 'atag');

    # If field is given, it must be a valid field index for the item or
    # an error will be reported.
    &test_no_eval ("accessing a non existing track field",
		   $log_level, "itemcget", 'track', 111, -text);

    # If the attribute is not available for the field or item type,
    # an error is reported.
    &test_no_eval ("accessing a non existing curve attribute",
		   $log_level, "itemcget", 'curve', -bad_attribute);
    &test_no_eval ("accessing a non existing attribute of a track field",
		   $log_level, "itemcget", 'track', 1, -bad_attribute);

    # If field is given, it must be a valid field index for the item or an
    # error will be reported.
    &test_no_eval ("modifying a non existing track field",
		   $log_level, "itemconfigure", 'track', 111, -text => "foo");
    # If an attribute does not belong to the item or field, an error is reported:
    &test_no_eval ("modifying a non existing curve attribute",
		   $log_level, "itemconfigure", 'curve', -bad_attribute => "foo");
    &test_no_eval ("modifying a non existing attribute of a track field",
		   $log_level, "itemconfigure", 'track', 1, -bad_attribute => "foo");

#    If tagOrId doesn t name an item, an error is raised.
    &test_no_eval ("lowering  a non-existing item with lower",
		   $log_level, "lower", 'badtag', 'track');
#    If belowThis doesn t name an item, an error is raised.
    &test_no_eval ("lowering  an existing below an non-existing item with lower",
		   $log_level, "lower", 'track', 'badtag');

#    If no items are named by tagOrId, an error is raised.
    &test_no_eval ("refering a non-existing item with numparts",
		   $log_level, "numparts", 'badtag');

#    If tagOrId describes neither a named transform nor an item, an error is raised.
    &test_no_eval ("refering a non-existing item with rotate",
		   $log_level, "rotate", 'badtag', 180);
#    If tagOrId describes neither a named transform nor an item, an error is raised.
    &test_no_eval ("refering a non-existing item with scale",
		   $log_level, "scale", 'badtag', 2,2);
#    If tagOrId describes neither a named transform nor an item, an error is raised.
    &test_no_eval ("refering a non-existing item with translate",
		   $log_level, "translate", 'badtag', 200,200);

    # If the given name is not found among the named transforms, an error is raised.
    &test_no_eval ("refering a non-existing named transform item with tdelete",
		   $log_level, "tdelete", 'badNamedTransform');

# ->transform ??

    # If tagOrId describes neither a named transform nor an item, an error is raised.
    &test_no_eval ("refering a non-existing named transform or item with treset",
		   $log_level, "treset", 'badNamedTransform');

    # If tagOrId doesn t describe any item or if the transform named tName
    # doesn't exist, an error is raised.
    &test_eval ($log_level, "tsave", "text", "namedTransfrom");
    &test_no_eval ("refering a non-existing item with trestore",
		   $log_level, "trestore", 'badTag', 'namedTransform');
    &test_no_eval ("refering a non-existing named transform with trestore",
		   $log_level, "trestore", 'track', 'badNamedTransform');

    # If tagOrId doesn t describe any item, an error is raised.
    &test_no_eval ("refering a non-existing item with tsave",
		   $log_level, "tsave", 'badTag', 'otherNamedTransform');

    # If no items are named by tagOrId, an error is raised.
    &test_no_eval ("refering a non-existing item with type",
		   $log_level, "type", 'badTag');
    
    &log (0, "#----  End of test_errors  -----\n");
} # end of test_errors

sub creating_items {
    # first removing all remaining items
    foreach my $tag qw(group track waypoint tabular text icon reticle map
			rectangle arc curve triangles window) {
	$zinc->remove($tag);
    }
    # and then creating items
    $zinc->add('group', 1, -tags => ['group']);
    $zinc->add('track', 1, 5, -position => [100,200], -tags => ['track']);
    $zinc->add('waypoint', 1, 5, -position => [200,100], -tags => ['waypoint']);
    $zinc->add('tabular', 1, 5, -position => [100,20], -tags => ['tabular']);
    $zinc->add('text',1, -tags => ['text']);
    $zinc->add('icon', 1, -tags => ['icon']);
    $zinc->add('reticle', 1, -tags => ['reticle']);
    $zinc->add('map', 1, -tags => ['map']);
    $zinc->add('rectangle', 1, [400,400 , 450,220], -tags => ['rectangle']);
    $zinc->add('arc', 1, [10,10 , 50,50], -tags => ['arc']);
    $zinc->add('curve', 1, [30,0 , 150,10, 100,110, 10,100, 50,140], -tags => ['curve']);
    $zinc->add('triangles', 1, [200,200 , 300,200 , 300,300, 200,300],
		-colors => ["blue;50", "red;20", "green;80"], -tags => ['triangles']);
    $zinc->add('window', 1, -tags => ['window']);
    foreach my $tag qw(group track waypoint tabular text icon reticle map
			rectangle arc curve triangles window) {
#	my $contour = $zinc->contour($tag);
#	print "$tag := $contour\n";
    }
    
} # end creating_items


sub verify_coords_of_contour {
    my ($predicat, $id1, $id2, $contour) = @_;
    my @contour1 = $zinc->coords($id1,$contour);
    my @contour2 = $zinc->coords($id2,$contour);
#    print "contour1: ", &printableArray (@contour1), "\n";
#    print "contour2: ", &printableArray (@contour2), "\n";
    my $res = &nequal_cplx_arrays (\@contour1, \@contour2);
#    print "res=$res\n";
    if ($predicat eq 'eq') {
	if ($res) {
	    &log(-100, "coords of $id1($contour) and $id2($contour) are not equal:\n\t".
		 &printableArray(@contour1)."\n\t".&printableArray(@contour2)."\n");
	} else {
	    &log(1, "  # coords of $id1($contour) and $id2($contour) are OK ($predicat)\n");
	}
    } elsif ($predicat eq 'ne') {
	if (!$res)  {
	    &log(-10, "coords of $id1($contour) and $id2($contour) should not be equal\n");
	} else {
	    &log(1, "  # coords of $id1($contour) and $id2($contour) are OK ($predicat)\n");
	}
    } else {
	&log(-100, "unknown predicat: $predicat\n");
    }
} # end of verify_coords_of_contour;


sub verify_coords_of_contour_points {
    my ($predicat, $id1, $id2, $contour) = @_;
    my @contour1 = $zinc->coords($id1,$contour);

    my $nequal=0;
    for (my $i = 0; $i < $#contour1; $i++) {
	my @coords1 = $zinc->coords($id1,0,$i);
	my @coords2 = $zinc->coords($id2,0,$i);
	my $res = &equal_flat_arrays ( \@coords1, \@coords2 );
	if ($predicat eq 'eq') {
	    if (!$res) {
		&log(-100, "coords of $id1($contour,$i) and $id2($contour,$i) are not equal:\n\t$res");
	    }
	} elsif ($predicat eq 'ne') {
	    if (!$res) {
		$nequal=$res;
		last;
	    }
	} else {
	    &log(-100, "unknown predicat: $predicat\n");
	 }   
    }
    if ($predicat eq 'neq' and !$nequal)  {
	&log(-100, "coords of $id1($contour,i) and $id2($contour,i) should not be all equal\n");
    } else {
	&log(1, "  # coords of $id1($contour,i) and $id2($contour,i) are OK ($predicat)\n");
    }
} # end of verify_coords_of_contour_points;


sub parseTestsOpt {
    my ($opt) = @_;
    my @tests;
    if ($opt eq '') {
	print "Availables tests are:\n";
	while (@testsList) {
	    my $i = shift @testsList;
	    my $comment = shift @testsList;
	    print "\t$i => $comment\n";
	}
	exit;
    } elsif ( $opt eq 'all' ) { ## default!
	&log (0, "  # all tests will be passed through\n");
	@tests = sort keys %testsHash;
    } elsif ( $opt =~ /^\d+(,\d+)*$/ ) {
	@tests = split (/,/ , $opt);
	my $testnumb = (scalar @testsList) / 2;
	foreach my $test (@tests) {
	    die "tests num must not exceed $testnumb" if $test > $testnumb;
	}
	&log(0,  "Test to be done:\n");
	foreach my $test (@tests) {
	    &log(0,  "\t # $test => " . $testsHash{$test} . "\n");
	}
    } else {
	print "bad -tests value. Must be a list of integer separated by ,\n";
	&usage;
    }
    return @tests;
} # end of parseTestsOpt

# ---------- TEST ------------------
# the following code must be coherent with the tests list described
# on the very beginning of this file (see @testsList definition)

if ($tests{1}) {
    &test_contour_and_coords ();
}

if ($tests{2}) {
    &test_forbidden_operations_on_root_group ();
}

if ($tests{3}) {
    &test_errors; 
}

if ($tests{4}) {
    &test_bboxes;
}

if ($tests{5}) {
    &test_gradient_coding;
}

### we should also test multicontour curves
if ($tests{5}) {
#    &test_coords;
}

# #### &test_fonts;  ## and specially big fonts with render = 1;
# #### &test_path_tags;
# #### &test_illegal_tags;

# #### &test_illegal_call
# for example:
#  calling a methode for an non-existing item
#  getting coords, contours, fields, etc... of non-existing index
#
#  cloning, deleting topgroup
#

&log (0, "#---- End of test_method ----\n");

#MainLoop();
