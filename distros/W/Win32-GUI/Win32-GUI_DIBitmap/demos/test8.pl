#!perl -w
use strict;
use warnings;

#
#  Test with Win32::GUI and GD
#
# Functions Test :
#    - newFromData
#    - StretchToDC

BEGIN {
   eval "use GD";
   die "GD module required for this script" if $@;
}

use Win32::GUI();
use Win32::GUI::DIBitmap;

# create a new image
my $im = new GD::Image(100,100);

# allocate some colors
my $white = $im->colorAllocate(255,255,255);
my $black = $im->colorAllocate(0,0,0);
my $red = $im->colorAllocate(255,0,0);
my $blue = $im->colorAllocate(0,0,255);

# make the background transparent and interlaced
$im->transparent($white);
$im->interlaced('true');

# Put a black frame around the picture
$im->rectangle(0,0,99,99,$black);

# Draw a blue oval
$im->arc(50,50,95,75,0,360,$blue);

# And fill it with red
$im->fill(50,50,$red);

my $dib = newFromData Win32::GUI::DIBitmap ($im->png) or die "newFromData";

undef $im;

my $W = new Win32::GUI::Window (
    -title    => "Win32::GUI::DIBitmap test",
    -pos      => [100, 100],
    -size     => [200, 200],
    -name     => "Window",
) or die "new Window";

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

