#!perl -w
use strict;
use warnings;

#
#  Test with Win32::GUI
#
# Functions Test :
#    - newFromBitmap
#    - StretchToDC

use FindBin();
use Win32::GUI();
use Win32::GUI::DIBitmap;

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

$W->Show();
Win32::GUI::Dialog();
exit(0);

sub Window_Paint {
	my $dc = shift;

    my ($width, $height) = ($W->GetClientRect)[2..3];

    $dib->StretchToDC($dc, 10, 10, $width - 20, $height - 20);
    $dib->StretchToDC($dc);
    $dib->StretchToDC($dc, 0, ($height / 2) - 30, 50, 50);
    $dib->StretchToDC($dc, 0, $height - 50      , 50, 50, 20, 20, 20, 20);

	$dc->Validate();
	return 1;
}

