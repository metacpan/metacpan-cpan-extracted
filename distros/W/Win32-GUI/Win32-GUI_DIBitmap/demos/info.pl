#!perl -w
use strict;
use warnings;

use Win32::GUI::DIBitmap();

print "FreeImage Version: ", Win32::GUI::DIBitmap::GetVersion(), "\n";
print Win32::GUI::DIBitmap::GetCopyright(), "\n";

my $count = Win32::GUI::DIBitmap::GetFIFCount();
print "Format\tReading\tWriting\tDescription\n";

for (my $fif = 0; $fif < $count; $fif++) {
    my $format = Win32::GUI::DIBitmap::GetFormatFromFIF($fif);
    my $desc   = Win32::GUI::DIBitmap::FIFDescription($fif);
    my $read   = Win32::GUI::DIBitmap::FIFSupportsReading($fif) ? "Y" : "N";
    my $write  = Win32::GUI::DIBitmap::FIFSupportsWriting($fif) ? "Y" : "N";
    my $export = "";
    $export .= " 1"  if (Win32::GUI::DIBitmap::FIFSupportsExportBPP($fif, 1));
    $export .= " 4" if (Win32::GUI::DIBitmap::FIFSupportsExportBPP($fif, 4));
    $export .= " 8" if (Win32::GUI::DIBitmap::FIFSupportsExportBPP($fif, 8));
    $export .= " 16" if (Win32::GUI::DIBitmap::FIFSupportsExportBPP($fif, 16));
    $export .= " 24" if (Win32::GUI::DIBitmap::FIFSupportsExportBPP($fif, 24));
    $export .= " 32" if (Win32::GUI::DIBitmap::FIFSupportsExportBPP($fif, 32));
    $export = " [Export =$export]" unless ($export eq "");

    print "$format\t$read\t$write\t$desc$export\n";  
}

