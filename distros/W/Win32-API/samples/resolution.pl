use strict;
use Win32::API;

use constant HORZRES   => 8;
use constant VERTRES   => 10;
use constant BITSPIXEL => 12;
use constant VREFRESH  => 116;

Win32::API->Import("gdi32", "CreateDC", ['P', 'P', 'P', 'P'], 'N',)
    or die "Can't import the CreateDC API:\n$!\n";
Win32::API->Import("gdi32", "GetDeviceCaps", ['N', 'N'], 'N',)
    or die "Can't import the GetDeviceCaps API:\n$!\n";
Win32::API->Import("gdi32", "DeleteDC", ['N'], 'V',)
    or die "Can't import the DeleteDC API:\n$!\n";

my $hdc = CreateDC("DISPLAY", 0, 0, 0);
if (!$hdc) {
    die "ERROR: can't open display!\n";
}

my %colors = (
    8  => "256 Color",
    16 => "High Color",
    24 => "True Color",
    32 => "True Color",
);

my $X   = GetDeviceCaps($hdc, HORZRES);
my $Y   = GetDeviceCaps($hdc, VERTRES);
my $BPP = GetDeviceCaps($hdc, BITSPIXEL);
my $HZ  = GetDeviceCaps($hdc, VREFRESH);

print "${X}x$Y $colors{$BPP} ($BPP Bit)\n";

DeleteDC($hdc);
