#!/usr/bin/perl -w

#
# $Id: Text2.t,v 1.4 2005/12/02 22:01:26 mertz Exp $
# Author: Christophe Mertz
#

# testing text item

# this script can be used with an optionnal argument, an integer giving
# the delay in seconds during which the graphic updates will be displayed
# this is usefull for visual inspection!

my $mw;
BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More tests => 69;
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

use strict;

my $zinc = $mw->Zinc(-render => 1,
		     -width => 400, -height => 1200)->pack;

like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");


my $g1 = $zinc->add('group',1, -tags => "gr1");


my $TEXT = "";

my @families = $mw->fontFamilies;
#print "families=@families\n";

my $family="courier";
if ( grep /^verdana$/i , @families) {
    $family = "verdana";
#    $family = "helvetica";
} elsif ( grep /^helvetica$/i , @families) {
    $family = "helvetica";
} elsif  ( grep /^arial$/i , @families) {
    $family = "arial";
}
#print "family=$family\n";

my $topLevel = $mw->Toplevel();
$topLevel->title("testing all ascii glyphs of $family");

my $zinc0 = $topLevel->Zinc(-render => 1,
			    -width => 300, 
			    -height => 400,)->pack;
like  ($zinc0, qr/^Tk::Zinc=HASH/ , "zinc0 has been created");

$zinc0->fontCreate("fonta", -family => $family, -size => -20, -weight => 'normal');

## doing updates after the mainloop is launched
## this avoids the bug #32 described in http://bugzilla.tkzinc.org/show_bug.cgi?id=32
## and the bug #48 http://bugzilla.tkzinc.org/show_bug.cgi?id=48

$zinc->after(10, \&testExecute);  

Tk::MainLoop;


sub testExecute {

    foreach my $row (2..15) {
        my $string = "";
        foreach my $col (0..15) {
            my $val = $row*16+$col;
            $string .= chr($val) unless $val == 127;
        }
        $zinc0->add('text', 1, -position => [10,$row*20-40], 
                    -text => $string, -font => 'fonta');
        &pass("adding text item n°$row with a $family font of size 20 and normal weight");
    }
    $zinc0->update;
    
    
    # creating text items with many different fonts:

    my $size = 8;
    my $y = 10 ;

    $zinc->fontCreate("font$size", -family => $family, -size => -$size, -weight => 'normal');


    # creating text items with many different fonts:
    $zinc->add('text', $g1, -position => [10,$y],  -tags => ["txt$size"], -font => "font$size",
               -text => "$size pixels $family");
    $zinc->remove('txt8');
    $zinc->fontDelete("font$size");
    $zinc->fontCreate("font$size", -family => $family, -size => -$size, -weight => 'normal');
    $zinc->add('text', $g1, -position => [10,$y],  -tags => ["txt$size"], -font => "font$size",
               -text => "$size pixels $family");
    




    foreach my $size (9..60) {
        $zinc->fontCreate("font$size", -family => $family, -size => -$size, -weight => 'normal');
        $zinc->add('text', $g1, -position => [10,$y],  -tags => ["txt$size"], -font => "font$size",
                   -text => "$size pixels $family");
        $zinc->update;
        
        # deleting both the font and the text item and recreating it 10 times
        foreach my $count (1..10) {
            $zinc->fontDelete("font$size");
            $zinc->remove('txt8');
            $zinc->fontCreate("font$size", -family => $family, -size => -$size, -weight => 'normal');
            $zinc->add('text', $g1, -position => [10,$y],  -tags => ["txt$size"], -font => "font$size",
                       -text => "$size pixels $family");
            $zinc->update;
        }
        &pass("creating and deleting 10 times a text item with a $family font of size $size");
        $y += $size;
    }


    &wait;

    # we should certainly test much much other things!

    diag("############## end of text test");
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



