#!perl -w
use strict;
use warnings;

die "This sample crashes perl when calling FreeImage_LockPage";
$|=1; #autoflush

#
#  Test with Win32::GUI and Multi-Page system
#
# Functions Test :
#    - newFromFile
#    - AppendPage
#    - GetPageCount
#    - LockPage 
#    - UnlockPage
#    - GetLockedPageNumbers 

use FindBin();
use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::DIBitmap;

# Create a MDIB bitmap

my $mdib = new Win32::GUI::MDIBitmap ("mdib.tiff", FIF_TIFF,)
   	or die "new";

for my $i (1..5) {
    my $dib = newFromFile Win32::GUI::DIBitmap ("$FindBin::Bin/$i.bmp")
        or die "Failed reading $i.bmp";
    $mdib->AppendPage ($dib);
}

#undef $mdib;

# Load a MDIB bitmap

#$mdib = newFromFile Win32::GUI::MDIBitmap ("mdib.tiff") or die "newFromFile";

print "Number of pages :", $mdib->GetPageCount(), "\n";

my $i = 0;

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

$W->AddButton (
    -name    => "Button",
    -text    => "Next",
    -pos     => [0 , 0],
);

$W->Show();
Win32::GUI::Dialog();
exit(0);

sub Button_Click {

  $i = $i + 1;
  $i = 0 if ($i >= $mdib->GetPageCount());

  print "Current page :", $i, "\n";
  $W->InvalidateRect(0);
}

sub Window_Paint {
	my $dc = shift;

    my ($width, $height) = ($W->GetClientRect)[2..3];

    print "Locking page $i\n";
	my $dib = $mdib->LockPage($i);
    print "Locked\n";

	#print $mdib->GetLockedPageNumbers(), "\n";

	#$dib->AlphaCopyToDC($dc, 50, 50);
	#$dib->CopyToDC($dc, 50, 50);
	#$dib->SaveToFile ("test.bmp");

    print "UnLocking\n";
	$mdib->UnlockPage($dib);
    print "UnLocked\n";

	$dc->Validate();
	return 1;
}
