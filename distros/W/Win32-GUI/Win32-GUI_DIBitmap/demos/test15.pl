#!perl -w
use strict;
use warnings;

#
#  Test with Win32::GUI
#

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

my $bcolor = $dib->HasBackgroundColor();
print "hascolor = $bcolor\n";

my $color = $dib->GetPixel(10,10);
print "Color = $color\n";

$dib->SetPixel(10, 10, 255);
$color = $dib->GetPixel(10,10);
print "Color = $color\n";

$dib = $dib->ConvertTo24Bits();
print "hascolor = $bcolor\n";

my @color = $dib->GetPixel(11,10);
print "Color = @color\n";

$dib->SetPixel(11, 10, 255, 0, 0);
@color = (0, 255, 0);
$dib->SetPixel(12, 10, @color);
@color = (0, 0, 255);
$dib->SetPixel(13, 10, \@color);

$W->Show();
Win32::GUI::Dialog();
exit(0);

sub Window_Paint {
	my $dc = shift;

    my ($width, $height) = ($W->GetClientRect)[2..3];

    $dib->StretchToDC($dc, 0, 0, $width, $height);

	$dc->Validate();
	return 1;
}

