#!perl -w
use strict;
use warnings;

#
#  Test with Win32::GUI
#
# Functions Test :
#    - newFromWindow
#    - SaveToFile

use FindBin();
use File::Path;
use Win32::GUI();
use Win32::GUI::DIBitmap();

my $out_dir = "$FindBin::Bin/test10_dir";
mkpath($out_dir);

my $W = new Win32::GUI::Window (
    -title    => "Win32::GUI::DIBitmap test : newFromWindow",
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

    my $dib = newFromWindow Win32::GUI::DIBitmap ($W->Capture1)
	    or die "newFromWindow";
    $dib->SaveToFile ("$out_dir/button.bmp");
}

sub Capture2_Click {

    my $dib = newFromWindow Win32::GUI::DIBitmap ($W)
	    or die "newFromWindow";
    $dib->SaveToFile ("$out_dir/window_1.bmp");

    $dib = newFromWindow Win32::GUI::DIBitmap ($W, 1)
	    or die "newFromWindow";
    $dib->SaveToFile ("$out_dir/window_2.bmp");
}

sub Capture3_Click {

    my $hwnd = Win32::GUI::GetDesktopWindow();
    my $dib = newFromWindow Win32::GUI::DIBitmap ($hwnd)
		or die "newFromWindow";
    $dib->SaveToFile ("$out_dir/screen.bmp");
    $dib->SaveToFile ("$out_dir/screen.png");
    $dib->SaveToFile ("$out_dir/screen.jpg");
    $dib->SaveToFile ("$out_dir/screen.tif");
}
