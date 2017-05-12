#!perl -w
use strict;
use warnings;

#
#  Test with Win32::GUI
#
# Functions Test :
#    - newFromBitmap
#    - ConvertToBitmap
#    - ConvertTo24Bits
#    - SaveToFile  with fif and flag

use FindBin();
use File::Path;
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

my $hbitmap = new Win32::GUI::Bitmap("$FindBin::Bin/zapotec.bmp")
   	or die ("new Bitmap");

my $dib = newFromBitmap Win32::GUI::DIBitmap ($hbitmap) or die "newFromBitmap";

undef $hbitmap;

$hbitmap = $dib->ConvertToBitmap() or die "ConvertToBitmap";

my $out_dir = "test5_dir";
mkpath($out_dir);
$dib->SaveToFile ("$out_dir/1.jpg", FIF_JPEG, JPEG_QUALITYSUPERB )
   	or die "SaveToFile";
$dib->SaveToFile ("$out_dir/2.jpg", FIF_JPEG, JPEG_QUALITYGOOD )
   	or die "SaveToFile";
$dib->SaveToFile ("$out_dir/3.jpg", FIF_JPEG, JPEG_QUALITYNORMAL )
   	or die "SaveToFile";
$dib->SaveToFile ("$out_dir/4.jpg", FIF_JPEG, JPEG_QUALITYAVERAGE)
   	or die "SaveToFile";
$dib->SaveToFile ("$out_dir/5.jpg", FIF_JPEG, JPEG_QUALITYBAD )
   	or die "SaveToFile";
undef $dib;

$W->AddLabel (
    -pos     => [0 , 0],
    -size    => [$width, $height],
    -bitmap  => $hbitmap,
    -name    => "Bitmap",
);

$W->Show();
Win32::GUI::Dialog();
rmtree($out_dir);
exit(0);

sub Window_Resize {
    $W->Bitmap->Resize($W->ScaleWidth, $W->ScaleHeight);
}

sub Window_Terminate {
    -1;
}


