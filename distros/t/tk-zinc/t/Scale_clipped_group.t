#!/usr/bin/perl -w

#
# $Id: Scale_clipped_group.t,v 1.2 2006/02/12 09:42:23 mertz Exp $
# Author: Christophe Mertz  mertz@intuilab.com, adapted from a script 
# reported by Daniel Etienne for a bug report in Tk::Zinc 3.2.96
#

use strict;

# testing all the import

BEGIN {
    if (!eval q{
        use Test::More tests => 1;
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
}
use Tk;

my $mw = MainWindow->new();
my $zinc = $mw->Zinc(-render => 0)->pack(-expand => 1, -fill => "both");


# creating the father group 1 and 2
my $fatherGroup1=$zinc->add("group", 1);
my $fatherGroup2=$zinc->add("group", 1);

$zinc->coords($fatherGroup1, [50,100]);
$zinc->coords($fatherGroup2, [200,100]);

# creating subGroup 1 and 2
my $subGroup1=$zinc->add("group", $fatherGroup1);
my $subGroup2=$zinc->add("group", $fatherGroup2);

# creating null sized rectangle 1 to clip the subgroup 1
my $rectangle1 = $zinc->add("rectangle", $subGroup1, [ [0, 0], [0, 0] ]);

$zinc->itemconfigure($subGroup1, -clip => $rectangle1);

# creating an icon in the sub-group
my $surroundimgfile = Tk->findINC("Tk.xbm");

my $surroundimg = $zinc->Bitmap(-file => $surroundimgfile,
				-foreground => 'sienna',
				);
my $icon1 = $zinc->add("icon", $subGroup1,
                       -image => $surroundimg,
                      );
my $icon2 = $zinc->add("icon", $subGroup2,
                       -image => $surroundimg,
                      );


## scaling fatherGroup1 makes an image visible on 3.2.96/3.3.2 TkZinc version
$zinc->scale($fatherGroup1, 0.8, 0.8);

##  test cannot be run directly since $zinc->update does not work properly 
##  when not in a  mainloop
##  so I use a timer to trigger tests after entering the mainloop

$zinc->after(10, \&testExecute);  

Tk::MainLoop;

sub testExecute {


    &wait ("You should see ONLY ONE ptk ICON (a camel), please INSPECT VISUALY!"); sleep 2;

    diag("############## Scale clipped group test");
    exit;

}


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


