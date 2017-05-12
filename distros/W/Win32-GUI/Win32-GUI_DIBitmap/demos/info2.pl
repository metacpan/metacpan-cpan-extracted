#!perl -w
use strict;
use warnings;

# Check save bit support.
# 16-32	bits JPEG automaticly converted in SaveToFile
# 16 bits PNG automaticly converted in SaveToFile

use Win32::GUI::DIBitmap();

print "FreeImage ", Win32::GUI::DIBitmap::GetVersion(), "\n";

my $count = Win32::GUI::DIBitmap::GetFIFCount();

print "Format\tWriting info\n";

my $dib1  = new Win32::GUI::DIBitmap (100,100,1);
my $dib4  = new Win32::GUI::DIBitmap (100,100,4);
my $dib8  = new Win32::GUI::DIBitmap (100,100,8);
my $dib16 = new Win32::GUI::DIBitmap (100,100,16);
my $dib24 = new Win32::GUI::DIBitmap (100,100,24);
my $dib32 = new Win32::GUI::DIBitmap (100,100,32);
my $f = "tmp";

for (my $fif = 0; $fif < $count; $fif++) {
    my $format = Win32::GUI::DIBitmap::GetFormatFromFIF($fif);
    #my $desc  = Win32::GUI::DIBitmap::FIFDescription($fif);

    if (Win32::GUI::DIBitmap::FIFSupportsWriting($fif)) {
        my $write = '';
        $write .= "1 "  if ( $dib1->SaveToFile($f, $fif)  ); unlink $f;
        $write .= "4 "  if ( $dib4->SaveToFile($f, $fif)  ); unlink $f;
        $write .= "8 "  if ( $dib8->SaveToFile($f, $fif)  ); unlink $f;
        $write .= "16 " if ( $dib16->SaveToFile($f, $fif) ); unlink $f;
        $write .= "24 " if ( $dib24->SaveToFile($f, $fif) ); unlink $f;
        $write .= "32 " if ( $dib32->SaveToFile($f, $fif) ); unlink $f;
        print "$format\t$write\n";  
    }
}

