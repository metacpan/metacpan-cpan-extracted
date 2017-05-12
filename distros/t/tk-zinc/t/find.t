#!/usr/bin/perl -w

#
# $Id: find.t,v 1.5 2005/06/23 18:10:34 mertz Exp $
# Author: Christophe Mertz
#

# testing find methods

# this script can be used with an optionnal argument, an integer giving
# the delay in seconds during which the graphic updates will be displayed
# this is usefull for visual inspection!

BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More tests => 22;
        1;
    }) {
        print "# tests only work properly with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
    if (!eval q{
	use Tk::Zinc;
 	1;
    }) {
        print "unable to load Tk::Zinc";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
    if (!eval q{
 	$mw = MainWindow->new();
 	1;
    }) {
        print "# tests only work properly when it is possible to create a mainwindow in your env\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }
}


$zinc = $mw->Zinc(-render => 0,
		  -width => 400, -height => 400)->pack;

like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");


### creating rectangles:
$g1 = $zinc->add('group',1, -tags => "gr1");
$text = $zinc->add('text', $g1, -position => [-100,-100]);
$g2 = $zinc->add('group',$g1, -tags => "gr2");

$rect11 = $zinc->add('rectangle', $g2, [ 10,10,40,40]);
$rect12 = $zinc->add('rectangle', $g2, [ 50,10,80,40]);
$rect13 = $zinc->add('rectangle', $g2, [ 90,10,120,40]);
$rect21 = $zinc->add('rectangle', $g2, [ 10,50,40,80]);
$rect22 = $zinc->add('rectangle', $g2, [ 50,50,80,80], -tags => 'middle');
$rect23 = $zinc->add('rectangle', $g2, [ 90,50,120,80]);
$rect31 = $zinc->add('rectangle', $g2, [ 10,90,40,120]);
$rect32 = $zinc->add('rectangle', $g2, [ 50,90,80,120]);
$rect33 = $zinc->add('rectangle', $g2, [ 90,90,120,120]);
$zinc->update;

my @list;

@list = $zinc->find('overlapping', 20,20,110,110, $g2);
&ok (&eq_array (\@list ,
		[ $rect33, $rect32, $rect31, $rect23, $rect22,  $rect21, $rect13, $rect12,  $rect11, ]),
     "find overlapping all rectangles");

@list = $zinc->find('enclosed', 20,20,110,110, $g2);
&ok (&eq_array (\@list ,
		[ $rect22 ]),
     "find enclosed  the middle rectangle");

@list = $zinc->find('enclosed', 0,0,110,110, $g2);
&ok (&eq_array (\@list ,
		[ $rect22 , $rect21, $rect12, $rect11 ]),
     "find enclosed  the 4 left up rectangles");

@list = $zinc->find('ancestor', $rect33);
&ok (&eq_array (\@list ,
		[ $g2 , $g1, 1 ]),
     "find ancestor of one rectangle");

@list = $zinc->find('withtag', ".gr1.");
#print "@list\n";
&ok (&eq_array (\@list ,
		[ $g2, $text, ]),
     "find direct descendant of group tagged gr1");

@list = $zinc->find('withtag', ".gr1*");
#print "@list\n";
&is_deeply ( [ @list ] ,
	     [ $g2, ($zinc->find('withtag', ".gr1.gr2*"), $text ) ],
	     "find all descendant of group tagged gr1");

&is_deeply ( [ ($zinc->find('withtag', ".gr1.gr2*")) ],
	     [ ($zinc->find('withtag', "*gr2*")) ],
	     "comparing full pathtag and reduced pathtag to a group");

&is_deeply ( [ ($zinc->find('withtag', ".gr1.gr2.middle")) ],
	     [ ($zinc->find('withtag', "*gr2.middle")) ],
	     "comparing full pathtag and reduced pathtag to a rectangle");

&is_deeply ( [ ($zinc->find('withtag', ".gr1.gr2.middle")) ],
	     [ ($zinc->find('withtag', "*middle")) ],
	     "comparing full pathtag and reduced pathtag to a rectangle");

&is_deeply ( [ ($zinc->find('withtag', ".gr1.gr2.middle")) ],
	     [ ($zinc->find('withtag', "middle")) ],
	     "comparing full pathtag and reduced pathtag to a rectangle");

&is_deeply ( [ ($zinc->find('withtype', "group")) ],
	     [ $g1, $g2 ],
	     "find with type 'group'");

&is_deeply ( [ ($zinc->find('withtype', "group", ".$g1.")) ],
	     [ $g2 ],
	     "find with type 'group' starting from g1");

&is_deeply ( [ ($zinc->find('withtype', "group", ".$g1.")) ],
	     [ ($zinc->find('withtype', "group", ".$g1*")) ],
	     "find with type 'group' starting from g1");

&is_deeply ( [ ($zinc->find('withtype', "rectangle")) ],
	     [ $rect33, $rect32, $rect31, $rect23, $rect22,  $rect21, $rect13, $rect12,  $rect11, ],
	     "find with type 'rectangle'");
&is_deeply ( [ ($zinc->find('withtype', "rectangle", ".$g1*")) ],
	     [ ($zinc->find('withtype', "rectangle")) ],
	     "find with type 'rectangle' starting from .g1*");


## testing overlapping find with atomic group (for testig the bug 
##   reported by D. Etienne the 11th June 04
$zinc->itemconfigure($g2, -atomic => 1);
@list = $zinc->find('overlapping', 20,20,110,110);
#print "overlapping17 (",join (',', @list),")   \$g2=$g2\n";
&ok (&eq_array (\@list ,
		[ $g2 ]),
     "find overlapping when group becomes atomic, without specifying starting group");

@list = $zinc->find('overlapping', 20,20,110,110,1);
#print "overlapping18 (",join (',', @list),")   \$g2=$g2\n";
&ok (&eq_array (\@list ,
		[ $g2 ]),
     "find overlapping when group becomes atomic, starting from group 1");

@list = $zinc->find('overlapping', 20,20,110,110,1,1);
&ok (&eq_array (\@list ,
		[ $g2 ]),
     "find overlapping when group becomes atomic, recursively, starting from group 1");


## testing enclosing find with atomic group
@list = $zinc->find('enclosed', 0,0,200,200);
#print "enclosing20 (",join (',', @list),")   \$g2=$g2\n";
&ok (&eq_array (\@list ,
		[ $g2 ]),
     "find enclosed when group becomes atomic, without specifying starting group");

@list = $zinc->find('enclosed', 0,0,200,200,  1);
#print "enclosing21 (",join (',', @list),")   \$g2=$g2\n";
&ok (&eq_array (\@list ,
		[ $g2 ]),
     "find enclosed when group becomes atomic, starting from group 1");

@list = $zinc->find('enclosed', 0,2,200,200,  1,1);
#print "enclosing22 (",join (',', @list),")   \$g2=$g2\n";
&ok (&eq_array (\@list ,
		[ $g2 ]),
     "find enclosed when group becomes atomic, recursively, starting from group 1");

# Tk::MainLoop;



sub wait {
    $zinc->update;
    ok (1, $_[0]);

    my $delay = $ARGV[0];
    if (defined $delay) {
	$zinc->update;
	if ($delay =~ /^\d+$/) {
	    sleep $delay;
	} else {
	    sleep 1;
	}
    }
    
}



diag("############## Images test");
