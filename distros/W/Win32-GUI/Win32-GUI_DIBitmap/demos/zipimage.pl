#!perl -w
use strict;
use warnings;

#
# Load image from a zip file.
# 

use FindBin();
use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::DIBitmap();
use Archive::Zip();

my $W = new Win32::GUI::Window (
    -title    => "Win32::GUI::DIBitmap load from a zipfile",
    -left     => 100,
    -top      => 100,
    -width    => 400,
    -height   => 400,
    -name     => "Window",
	-pushstyle => WS_CLIPCHILDREN,
) or die "new Window";

my ($width, $height) = ($W->GetClientRect)[2..3];

# Open Zipfile
my $zip = Archive::Zip->new( "$FindBin::Bin/zapotec.zip" ) or die "ZipFile";
# Open image file in zipfile
my $member = $zip->memberNamed( 'Zapotec.JPG' ) or die "member ZipFile";
# Load data image in memory
my $data = $member->contents();
# Load  data immage in a dibbitmap
my $dib = newFromData Win32::GUI::DIBitmap ($data) or die "Load zapotec.jpg";
my $hbitmap = $dib->ConvertToBitmap();

undef $member;
undef $zip;
undef $data;
undef $dib;

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
