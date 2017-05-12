#!perl -w
use strict;
use warnings;

#
#  Test with Win32::GUI
#
# Functions Test :
#    - newFromDC
#    - SaveToFile

use FindBin();
use File::Path;
use Win32::GUI();
use Win32::GUI::DIBitmap;

my $out_dir = "$FindBin::Bin/test9_dir";
mkdir($out_dir);

my $W = new Win32::GUI::Window (
    -title    => "Win32::GUI::DIBitmap test: NewFromDC",
    -pos      => [100, 100],
    -size     => [300, 200],
    -name     => "Window",
) or die "new Window";

$W->AddButton (
    -name => "Capture1",
    -text => "Click here for capture this button",
    -pos  => [20, 40],
);

$W->AddButton (
    -name => "Capture2",
    -text => "Click here for capture this window",
    -pos  => [20, 80],
);

$W->AddButton (
    -name => "Capture3",
    -text => "Click here for capture the screen",
    -pos  => [20, 120],
);

$W->Show();
Win32::GUI::Dialog();
rmtree($out_dir);
exit(0);


sub Capture1_Click {

    my $dc = new Win32::GUI::DC ($W);
    my $dib = newFromDC Win32::GUI::DIBitmap ($dc,
        $W->Capture1->Left,
	    $W->Capture1->Top,
	    $W->Capture1->Width(),
	    $W->Capture1->Height()) or die "newFromDC";
    $dib->SaveToFile ("$out_dir/button.bmp");
}

sub Capture2_Click {

    my $dc = new Win32::GUI::DC ($W);
    my $dib = newFromDC Win32::GUI::DIBitmap ($dc) or die "newFromDC";
    $dib->SaveToFile ("$out_dir/window.bmp");
}

sub Capture3_Click {

    #my $dc = new Win32::GUI::DC ('DISPLAY');
    my $dc = new Win32::GUI::DC ();
    my $dib = newFromDC Win32::GUI::DIBitmap ($dc) or die "newFromDC";
    $dib->SaveToFile ("$out_dir/screen.bmp");
}
