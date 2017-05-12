#!perl -w
use strict;
use warnings;

#
#  Test with Win32::GUI
#
# Functions Test :
#    - newFromBitmap
#    - CopyToDC
#    - AlphaCopyToDC
#    - AlphaStretchToDC

use FindBin();
use Win32::GUI();
use Win32::GUI::DIBitmap();

my $W = new Win32::GUI::Window (
    -title    => "Win32::GUI::DIBitmap test",
    -left     => 100,
    -top      => 100,
    -width    => 400,
    -height   => 400,
    -name     => "Window",
) or die "new Window";

my $dib = newFromFile Win32::GUI::DIBitmap ("$FindBin::Bin/zapotec.bmp")
   	or die "newFromFile";
my $dibalpha = newFromFile Win32::GUI::DIBitmap ("$FindBin::Bin/small.tga")
	or die "newFromFile";

print "Transparent : ", $dibalpha->IsTransparent(), "\n";
print "BPP : ", $dibalpha->GetBPP(), "\n";

$W->Show();
Win32::GUI::Dialog();
exit(0);

sub Window_Paint {
	my $dc = shift;

    my ($width, $height) = ($W->GetClientRect)[2..3];

    $dib->StretchToDC($dc, 10, 10, $width - 20, $height - 20);
    $dibalpha->CopyToDC($dc);
    $dibalpha->AlphaCopyToDC($dc, 200);
    $dibalpha->AlphaStretchToDC($dc, 0, 200, 260, 200 );
    $dc->Validate();
    return 1;
}

