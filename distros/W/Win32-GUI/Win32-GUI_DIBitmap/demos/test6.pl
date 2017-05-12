#!perl -w
use strict;
use warnings;

#
#  Test with Win32::GUI
#
# Functions Test :
#    - newFromBitmap
#    - CopyToDC

use FindBin();
use Win32::GUI qw();
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
	#$dc = new Win32::GUI::DC ($W);

    $dib->CopyToDC($dc);
    $dib->CopyToDC($dc, ($width / 2) - 30, ($height / 2) - 30 , 60, 60);
    $dib->CopyToDC($dc, $width - 50, $height - 50, 50, 50, 20, 10);
	
	$dc->Validate();
	return 1;
}

