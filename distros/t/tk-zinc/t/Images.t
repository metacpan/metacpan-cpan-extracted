#!/usr/bin/perl -w

#
# $Id: Images.t,v 1.8 2006/02/12 09:40:55 mertz Exp $
# Author: Christophe Mertz
#

# testing all the -tile, -image, -mask, -fillpattern, -linepattern widget and items options 

# this script can be used with an optionnal argument, an integer giving
# the delay in seconds during which the graphic updates will be displayed
# this is usefull for visual inspection!

BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More tests => 36;
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


$zinc = $mw->Zinc(-render => 1,
		  -width => 400, -height => 400)->pack;

like  ($zinc, qr/^Tk::Zinc=HASH/ , "zinc has been created");

##  test cannot be run directly since $zinc->update does not work properly 
##  when not in a  mainloop
##  so I use a timer to trigger tests after entering the mainloop

$zinc->after(10, \&testExecute);  

Tk::MainLoop;

sub testExecute {

#### creating different images, bitmaps and pixmaps...
my $photoMickey = $zinc->Photo('mickey.gif', -file => Tk->findINC("demos/images/mickey.gif"));
like ($photoMickey, qr/^Tk::Photo=HASH/ , "creating a Tk::Photo with a .gif");

my $bitmap = $zinc->Bitmap('file.xbm', -file => Tk->findINC("file.xbm"));
like ($bitmap, qr/^Tk::Bitmap=HASH/ , "creating a Tk::Bitmap with a .xbm");

my $xpm = $zinc->Photo('QuitPB.xpm', -file => Tk->findINC("demos/images/QuitPB.xpm"));
like ($xpm, qr/^Tk::Photo=HASH/ , "creating a Tk::Photo with a .xpm");

#### tiling Tk::Zinc
$zinc->configure(-tile => $xpm);
if ($Tk::VERSION < 804) {
  is ($zinc->cget(-tile), "QuitPB.xpm", "verifying Tk::Zinc -tile option value");
} else {
  is ($zinc->cget(-tile), $xpm, "verifying Tk::Zinc -tile option value");
}

&wait ("-tile of Tk::Zinc with QuitPB.xpm");

$zinc->configure(-tile => $photoMickey);
if ($Tk::VERSION < 804) {
  is ($zinc->cget(-tile), "mickey.gif", "verifying Tk::Zinc -tile option value");
} else {
  is ($zinc->cget(-tile), $photoMickey, "verifying Tk::Zinc -tile option value");
}
&wait ("-tile of Tk::Zinc with mickey.gif");

# modifying the Tk::Photo to see if the Tk::Zinc -tile changes
$photoMickey->read( Tk->findINC("demos/images/earth.gif") );
&wait ("-tile of Tk::Zinc should display the earth VISUAL INSPECTION!"); sleep 1;
# going back to the "real" mickey
$photoMickey->read( Tk->findINC("demos/images/mickey.gif") );
&wait ("-tile of Tk::Zinc should display mickey again VISUAL INSPECTION!"); sleep 1;

$zinc->configure(-tile => "");
if ($Tk::VERSION < 804) {
  is ($zinc->cget(-tile), "", "removing Tk::Zinc -tile");
} else {
  is ($zinc->cget(-tile), undef, "removing Tk::Zinc -tile");
}
&wait ("-tile of Tk::Zinc with nothing");



#### rectangle item
my $rect1 = $zinc->add('rectangle', 1, [10,10,190,190], -filled => 1);


$zinc->itemconfigure($rect1, -tile => $xpm);

if ($Tk::Zinc::VERSION < 3.302) {
  is ($zinc->itemcget($rect1, -tile), "QuitPB.xpm", "verifying rectangle -tile option value");
} else {
  # cget return an image object since release 3.3.2
  is ($zinc->itemcget($rect1, -tile), $xpm, "verifying rectangle -tile option value");
}
&wait ("-tile of rectangle with QuitPB.xpm");

$zinc->itemconfigure($rect1, -tile => $photoMickey);
if ($Tk::Zinc::VERSION < 3.302) {
  is ($zinc->itemcget($rect1, -tile), "mickey.gif", "verifying rectangle -tile option value");
} else {
  # cget return an image object since release 3.3.2
  is ($zinc->itemcget($rect1, -tile), $photoMickey, "verifying rectangle -tile option value");
}

&wait ("-tile of rectangle with mickey");

# modifying the Tk::Photo to see if the rectangle -tile changes
$photoMickey->read( Tk->findINC("demos/images/earth.gif") );
&wait ("-tile of rectangle should display the earth VISUAL INSPECTION!"); sleep 1;
# going back to the "real" mickey
$photoMickey->read( Tk->findINC("demos/images/mickey.gif") );
&wait ("-tile of rectangle should display mickey again VISUAL INSPECTION!"); sleep 1;


$zinc->itemconfigure($rect1, -tile => "");
is ($zinc->itemcget($rect1, -tile), "", "removing rectangle -tile");
&wait ("-tile of rectangle with nothing");

TODO: {
    local $TODO = "because it makes Tk::Zinc dying" if 1;

    # the next line makes Tk::Zinc (v3.29x) dying... so I comment it out the 3 next lines 
    # $zinc->itemconfigure($rect1, -fillpattern => $bitmap);
    # is ($zinc->itemcget($rect1, -fillpattern), $bitmap, "verifying rectangle -fillpattern option value as a Tk::Bitmap");
    # &wait ("displaying a rectangle with -fillpattern as a Tk::Bitmap");
}

$zinc->itemconfigure($rect1, -fillpattern => 'AlphaStipple3');
is ($zinc->itemcget($rect1, -fillpattern), 'AlphaStipple3', "verifying rectangle -fillpattern option value");
&wait ("-fillpattern of rectangle with 'AlphaStipple3'");

$zinc->itemconfigure($rect1, -fillpattern => "");
is ($zinc->itemcget($rect1, -fillpattern), "", "removing rectangle -fillpattern");
&wait ("-fillpattern of rectangle with nothing");


$zinc->itemconfigure($rect1, -filled => 0,-linepattern => 'AlphaStipple3', -linecolor => "red");
is ($zinc->itemcget($rect1, -linepattern), 'AlphaStipple3', "verifying rectangle -linepattern option value");
&wait ("-linepattern of rectangle with 'AlphaStipple3'");

$zinc->itemconfigure($rect1, -linepattern => "");
is ($zinc->itemcget($rect1, -linepattern), "", "removing rectangle -linepattern");
&wait ("-linepattern of rectangle with nothing");

$zinc->remove($rect1);

#####  icon item
my $icon1 = $zinc->add('icon', 1, -position => [20,100], -image => $photoMickey);
&wait ("displaying an icon");

$zinc->remove($icon1);

my $icon2 = $zinc->add('icon', 1, -position => [40,100]);

SKIP: {
    skip "with Tk::Zinc < 3.295", 4 if ($Tk::Zinc::VERSION < 3.295);

    $zinc->itemconfigure($icon2, -image => $bitmap);

    &wait ("displaying an icon with -image as a Tk::Bitmap");
    if ($Tk::Zinc::VERSION < 3.302) {
      is ($zinc->itemcget($icon2, -image), 'file.xbm', "verifying icon -image option value as file.xbm");
    } else {
      # cget return an image object since release 3.3.2
      is ($zinc->itemcget($icon2, -image), $bitmap, "verifying icon -image option value as file.xbm");
    }
$zinc->itemconfigure($icon2, -image => "");

    $zinc->itemconfigure($icon2, -image => '@'.Tk->findINC("openfile.xbm"));
    if ($Tk::Zinc::VERSION < 3.302) {
      is ($zinc->itemcget($icon2, -image), '@'.Tk->findINC("openfile.xbm"),"verifying icon -image option value as @/path/openfile.xbm");
    } else {
      # cget return an image object since release 3.3.2
      is ($zinc->itemcget($icon2, -image), undef,"verifying icon -image option value as @/path/openfile.xbm");
    }
    &wait ("displaying an icon with -image as a \@filename.xbm");
}
$zinc->remove($icon2);

my $icon3 = $zinc->add('icon', 1, -position => [60,100], -mask => '@'.Tk->findINC("openfolder.xbm"),
		       -color => "red");
is ($zinc->itemcget($icon3, -mask), '@'.Tk->findINC("openfolder.xbm"),"verifying icon -mask option value as \@/path/openfolder.xbm");
&wait ("displaying an icon with -mask as a \@filename.xbm");

$zinc->itemconfigure($icon3, -image => "");
is ($zinc->itemcget($icon3, -image), "", "removing icon -image");

TODO: {
    local $TODO = "because it makes Tk::Zinc dying" if 1;

    # the next line makes Tk::Zinc (v3.29x) dying... so I comment it out the 3 next lines 
    # $zinc->itemconfigure($icon3, -mask => $bitmap);
    # is ($zinc->itemcget($icon3, -mask), $bitmap, "verifying icon -mask option value as a Tk::Bitmap");
    # &wait ("displaying an icon with -mask as a Tk::Bitmap");
}

$zinc->remove($icon3);

# We should also test that changing the content of a Tk::Photo should change the display of an icon


diag("############## Images test");
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



