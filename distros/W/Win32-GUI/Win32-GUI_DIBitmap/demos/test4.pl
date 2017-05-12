#!perl -w
use strict;
use warnings;

#
#  Test with Win32::GUI 
# 
# Functions Test :
#    - newFromFile
#    - ConvertToBitmap

use FindBin();
use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::DIBitmap;

my $W = new Win32::GUI::Window (
    -title    => "Win32::GUI::DIBitmap test",
    -left     => 100,
    -top      => 100,
    -width    => 400,
    -height   => 400,
    -name     => "Window",
	-pushstyle => WS_CLIPCHILDREN,
) or die "new Window";

my ($width, $height) = ($W->GetClientRect)[2..3];

my $dib = newFromFile Win32::GUI::DIBitmap ("$FindBin::Bin/zapotec.jpg")
   	or die "Load zapotec.jpg";
my $hbitmap = $dib->ConvertToBitmap();
undef $dib;

# $hbitmap = new Win32::GUI::Bitmap('bmp/zapotec.bmp') or die ("new Bitmap");

$W->AddLabel (
    -pos     => [0 , 0],
    -size    => [$width, $height],
    -bitmap  => $hbitmap,
    -name    => "Bitmap",
);

$W->Show();
Win32::GUI::Dialog();
exit(0);

sub Window_Resize {
    $W->Bitmap->Resize($W->ScaleWidth, $W->ScaleHeight);
}

sub Window_Terminate {
	-1;
}


