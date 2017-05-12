#!/usr/bin/perl -w
# $Id: curve_bezier.pl,v 1.6 2004/09/21 12:45:38 mertz Exp $
# This simple demo has been developped by C. Mertz <mertz@cena.fr>

####### This file has been initially inspired from svg examples

package curveBezier;

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

use Tk::Zinc;


my $mw = MainWindow->new();
$mw->title('example of curves with cubic control points');

my $text = $mw->Text (-relief => 'sunken', -borderwidth => 2,
		      -setgrid => 'true',  -height =>3);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
'6 examples of curves containing control points are displayed, 
 with the list of control points written just below.
You can move the handles to modify the bezier curves');


my $zinc = $mw->Zinc(-width => 700, -height => 650,
		     -font => "10x20",
		     -font => "9x15",
		     -borderwidth => 0,
                     -backcolor => "white",
		     -forecolor => "grey80",
		     -render => 1, # this demo also works without openGL
		     # with openGL, antialiasing makes the curves nicer
		      )->pack;

my $group = $zinc->add('group', 1);

$zinc->add('text',$group, -position => [50,20], -anchor => 'w',
	   -text => "Examples of curve items using cubic bezier control points",
	   -color => "grey20");

## Please note: much of the following items below could be computed
$zinc->add('text',$group, -position => [25,270], -anchor => 'w', -tags => ['bezier1'], -color => "grey20");
$zinc->add('curve',$group,[100, 200, 100, 100], -tags => ['line1', 'l1-2'], -linecolor => "#888888", -filled => 0, -linewidth => 2);
$zinc->add('curve',$group,[400, 100, 400, 200], -tags => ['line1', 'l3-4'], -linecolor => "#888888", -filled => 0, -linewidth => 2);
$zinc->add('curve',$group,[[100, 200], [100, 100, 'c'], [400, 100, 'c'], [400, 200]],
	   -tags => ['bezier1'], -closed => 0, -linecolor => "red", -linewidth => 5);
$zinc->add('arc',$group,[90, 190, 110, 210], -tags => ['handle1',"p1"], -filled => 1, -fillcolor => "#BBBBBB");
$zinc->add('arc',$group,[90, 90, 110, 110], -tags => ['handle1',"p2"], -filled => 1, -linewidth => 0, -fillcolor => "grey80", -filled => 1);
$zinc->add('arc',$group,[390, 90, 410, 110], -tags => ['handle1',"p3"], -filled => 1, -linewidth => 0, -fillcolor => "grey80", -filled => 1);
$zinc->add('arc',$group,[390, 190, 410, 210], -tags => ['handle1',"p4"], -filled => 1, -fillcolor => "#BBBBBB");

$zinc->add('text',$group, -position => [570,270], -anchor => 'w', -tags => ['bezier2'], -color => "grey20");
$zinc->add('curve',$group,[600, 200, 675, 100], -tags => ['line2', 'l1-2'], -linecolor => "#888888", -linewidth => 2);
$zinc->add('curve',$group,[975, 100, 900, 200], -tags => ['line2', 'l3-4'], -linecolor => "#888888", -linewidth => 2);
$zinc->add('curve',$group,[[600, 200], [675, 100, 'c'], [975, 100, 'c'], [900, 200]],
	   -tags => ['bezier2'], -closed => 0, -linecolor => "red", -linewidth => 5);
$zinc->add('arc',$group,[590, 190, 610, 210], -tags => ['handle2',"p1"], -filled => 1, -linecolor => "grey80", -linewidth => 2);
$zinc->add('arc',$group,[665, 90, 685, 110], -tags => ['handle2',"p2"], -filled => 1, -linewidth => 0, -fillcolor => "grey80");
$zinc->add('arc',$group,[965, 90, 985, 110], -tags => ['handle2',"p3"], -filled => 1, -linewidth => 0, -fillcolor => "grey80");
$zinc->add('arc',$group,[890, 190, 910, 210], -tags => ['handle2',"p4"], -filled => 1, -linecolor => "grey80", -linewidth => 2);

$zinc->add('text',$group, -position => [25,570], -anchor => 'w', -tags => ['bezier3'], -color => "grey20");
$zinc->add('curve',$group,[100, 500, 25, 400], -tags => ['line3', 'l1-2'], -linecolor => "#888888", -linewidth => 2);
$zinc->add('curve',$group,[475, 400, 400, 500], -tags => ['line3', 'l3-4'], -linecolor => "#888888", -linewidth => 2);
$zinc->add('curve',$group,[[100, 500], [25, 400, 'c'], [475, 400, 'c'], [400, 500]],
	   -tags => ['bezier3'], -closed => 0, -linecolor => "red", -linewidth => 5);
$zinc->add('arc',$group,[90, 490, 110, 510], -tags => ['handle3',"p1"], -filled => 1, -linecolor => "grey80", -linewidth => 2);
$zinc->add('arc',$group,[15, 390, 35, 410], -tags => ['handle3',"p2"], -filled => 1, -linewidth => 0, -fillcolor => "grey80", );
$zinc->add('arc',$group,[465, 390, 485, 410], -tags => ['handle3',"p3"], -filled => 1, -linewidth => 0, -fillcolor => "grey80", );
$zinc->add('arc',$group,[390, 490, 410, 510], -tags => ['handle3',"p4"], -filled => 1, -linecolor => "grey80", -linewidth => 2);

$zinc->add('text',$group, -position => [570,570], -anchor => 'w', -tags => ['bezier4'], -color => "grey20");
$zinc->add('curve',$group,[600, 500, 600, 350], -tags => ['line4', 'l1-2'], -linecolor => "#888888", -linewidth => 2);
$zinc->add('curve',$group,[900, 650, 900, 500], -tags => ['line4', 'l3-4'], -linecolor => "#888888", -linewidth => 2);
$zinc->add('curve',$group,[[600, 500], [600, 350, 'c'], [900, 650, 'c'], [900, 500]], -tags => ['bezier4'], -closed => 0, -linecolor => "red", -linewidth => 5);
$zinc->add('arc',$group,[590, 490, 610, 510], -tags => ['handle4',"p1"], -filled => 1, -linecolor => "grey80", -linewidth => 2);
$zinc->add('arc',$group,[590, 340, 610, 360], -tags => ['handle4',"p2"], -filled => 1, -linewidth => 0, -fillcolor => "grey80");
$zinc->add('arc',$group,[890, 640, 910, 660], -tags => ['handle4',"p3"], -filled => 1, -linewidth => 0, -fillcolor => "grey80");
$zinc->add('arc',$group,[890, 490, 910, 510], -tags => ['handle4',"p4"], -filled => 1, -linecolor => "grey80", -linewidth => 2);

$zinc->add('text',$group, -position => [25,870], -anchor => 'w', -tags => ['bezier5'], -color => "grey20");
$zinc->add('curve',$group,[100, 800, 175, 700], -tags => ['line5', 'l1-2'], -linecolor => "#888888", -filled => 0, -linewidth => 2);
$zinc->add('curve',$group,[325, 700, 400, 800], -tags => ['line5', 'l3-4'], -linecolor => "#888888", -filled => 0, -linewidth => 2);
$zinc->add('curve',$group,[[100, 800], [175, 700, 'c'], [325, 700, 'c'], [400, 800]],
	   -tags => ['bezier5'], -closed => 0, -linecolor => "red", -linewidth => 5);
$zinc->add('arc',$group,[90, 790, 110, 810], -tags => ['handle5',"p1"], -filled => 1, -linecolor => "grey80", -linewidth => 2);
$zinc->add('arc',$group,[165, 690, 185, 710], -tags => ['handle5',"p2"], -filled => 1, -linewidth => 0, -fillcolor => "grey80", -filled => 1);
$zinc->add('arc',$group,[315, 690, 335, 710], -tags => ['handle5',"p3"], -filled => 1, -linewidth => 0, -fillcolor => "grey80", -filled => 1);
$zinc->add('arc',$group,[390, 790, 410, 810], -tags => ['handle5',"p4"], -filled => 1, -linecolor => "grey80", -linewidth => 2);

$zinc->add('text',$group, -position => [570,980], -anchor => 'w', -tags => ['bezier6'], -color => "grey20");
$zinc->add('curve',$group,[600, 800, 625, 700], -tags => ['line6', 'l1-2'], -linecolor => "#888888", -linewidth => 2);
$zinc->add('curve',$group,[725, 700, 750, 800], -tags => ['line6', 'l3-4'], -linecolor => "#888888", -linewidth => 2);
$zinc->add('curve',$group,[750, 800, 775, 900], -tags => ['line6', 'l4-5'], -linecolor => "#888888", -linewidth => 2);
$zinc->add('curve',$group,[875, 900, 900, 800], -tags => ['line6', 'l6-7'], -linecolor => "#888888", -linewidth => 2);
$zinc->add('curve',$group,[[600, 800], [625, 700, 'c'], [725, 700, 'c'], [750, 800], [775, 900, 'c'], [875, 900, 'c'], [900, 800]],
	   -tags => ['bezier6'], -filled => 0, -closed => 0, -linecolor => "red", -linewidth => 5);
$zinc->add('arc',$group,[590, 790, 610, 810], -tags => ['handle6',"p1"], -filled => 1, -linecolor => "grey80", -linewidth => 2);
$zinc->add('arc',$group,[615, 690, 635, 710], -tags => ['handle6',"p2"], -filled => 1, -linewidth => 0, -fillcolor => "grey80");
$zinc->add('arc',$group,[715, 690, 735, 710], -tags => ['handle6',"p3"], -filled => 1, -linewidth => 0, -fillcolor => "grey80");
$zinc->add('arc',$group,[740, 790, 760, 810], -tags => ['handle6',"p4"], -filled => 1, -linecolor => "blue",-fillcolor => "blue", -linewidth => 2);
$zinc->add('arc',$group,[766, 891, 784, 909], -tags => ['handle6',"p5"], -filled => 1, -linecolor => "grey80", -linewidth => 4);
$zinc->add('arc',$group,[865, 890, 885, 910], -tags => ['handle6',"p6"], -filled => 1, -linewidth => 0, -fillcolor => "grey80");
$zinc->add('arc',$group,[890, 790, 910, 810], -tags => ['handle6',"p7"], -filled => 1, -linecolor => "grey80", -linewidth => 2);

$zinc->scale($group, 0.6, 0.6);

## Set the text of the text item with a tag "tag"
## to a human-readable form of the coords of the
## corresponding curve with the same tag "tag"
sub setText {
    my ($tag) = @_;
    my $textItem = $zinc->find("withtype", 'text', $tag);
    my $curveItem = $zinc->find("withtype", 'curve', $tag);
    my @coords = $zinc->coords($curveItem);
    my $count = 0;
    my $text = "[ ";
    while (@coords) {
	$refXYc = pop @coords;
	my $x=sprintf "%i", $refXYc->[0];
	my $y=sprintf "%i", $refXYc->[1];
	my $t=$refXYc->[2];
	$t = (defined $t) ? ", '".$t."'" : "" ;
	$text .= "[$x, $y$t]";
	if (@coords) { $text .= ", "; }
	if ($count and @coords) {
	    $text .= "\n   ";
	    $count =0;
	} else {
	    $count++;
	}
    }
    $text .= " ]";
    $zinc->itemconfigure($textItem, -text => $text);
}

foreach my $bezierCount (1..6) {
    &setText ("bezier".$bezierCount);
    my $curveItem = $zinc->find("withtype", 'curve', "bezier".$bezierCount);
    my @coords = $zinc->coords($curveItem);
#    print "$bezierCount : ", scalar @coords, "\n";
    $zinc->bind("handle$bezierCount", '<ButtonPress-1>', [\&press, \&motion]);
    $zinc->bind("handle$bezierCount", '<ButtonRelease-1>', [\&release]);
}



&Tk::MainLoop;


##### bindings for moving the handles
my ($cur_x, $cur_y,$item, $bezierNum, $ptNum);
sub press {
    my ($zinc, $action) = @_;
    my $ev = $zinc->XEvent();
    $cur_x = $ev->x;
    $cur_y = $ev->y;
    $item = $zinc->find('withtag', 'current');
    $zinc->bind($item, '<Motion>', [$action]);
    foreach ( $zinc->gettags($item) ) {
	## looking for the tag "handlei"
	if ( /^handle(\d+)$/ ) {
	    $bezierNum = $1;
	}
	## looking for the tag "pj"
	if ( /^p(\d+)$/ ) {
	    $ptNum = $1;
	}
    }
#    print "bezierNum=$bezierNum ptNum=$ptNum\n";
}

sub motion {
    my ($zinc) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my ($dx,$dy) = $zinc->transform($group, [$lx-$cur_x, $ly-$cur_y]);
    &moveHandle($item,$dx,$dy);
    my ($pt1,$pt2) = $zinc->coords($item);
#    print "coords=",@{$pt1}, " ",@{$pt2},"\n";
    $cur_x = $lx;
    $cur_y = $ly;
}

sub release {
    my ($zinc) = @_;
    $zinc->bind($item,'<Motion>', '');
    $item = "";
}

sub moveHandle {
    my ($item,$dx,$dy) = @_;
    my ($pt1,$pt2) = $zinc->coords($item);
    ## modifying the handle coords
    $zinc->coords($item, [ $pt1->[0]+$dx, $pt1->[1]+$dy, $pt2->[0]+$dx, $pt2->[1]+$dy]);
    my $prevPtNum = $ptNum-1;
    # there should only be one such item!
    my $lineA = $zinc->find("withtag", "line$bezierNum && l$prevPtNum-$ptNum");
    if (defined $lineA) {
	my ($x,$y) = $zinc->coords($lineA,0,1); # to get the 2nd point coords
	$zinc->coords($lineA, 0,1, [ $x+$dx, $y+$dy ]);
    }

    my $nextPtNum = $ptNum+1;
    # there should only be one such item:
    my ($lineB) = $zinc->find("withtag", "line$bezierNum && l$ptNum-$nextPtNum");
    if (defined $lineB) {
	my ($x,$y) = $zinc->coords($lineB,0,0); # to get the 1st point coords
	$zinc->coords($lineB, 0,0, [ $x+$dx, $y+$dy ] );
    }

    my ($x,$y,$control) = $zinc->coords("bezier$bezierNum", 0,$ptNum-1);
    $zinc->coords("bezier$bezierNum", 0,$ptNum-1, [ [$x+$dx, $y+$dy, $control] ] );
    &setText ("bezier$bezierNum");
	
}
    
