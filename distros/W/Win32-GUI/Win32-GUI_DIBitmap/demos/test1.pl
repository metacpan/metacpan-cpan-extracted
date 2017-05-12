#perl -w
use strict;
use warnings;

#
# Test standalone :  
#
# Functions Test :
#    - GetVersion
#    - GetCopyright
#    - GetFIFCount
#    - GetFormatFromFIF
#    - GetFIFFromFormat
#    - FIFExtensionList
#    - FIFDescription
#    - FIFRegExpr
#    - FIFSupportsWriting
#    - FIFSupportsReading
#    - new
#    - SaveToFile

use Win32::GUI::DIBitmap;

print Win32::GUI::DIBitmap::GetVersion(), "\n";

print Win32::GUI::DIBitmap::GetCopyright(), "\n";

my $count = Win32::GUI::DIBitmap::GetFIFCount();

print "count = $count\n";

for (my $i = 0; $i < $count; $i++) {

  my $format = Win32::GUI::DIBitmap::GetFormatFromFIF($i);

  my $fif   = Win32::GUI::DIBitmap::GetFIFFromFormat($format);

  my $ext   = Win32::GUI::DIBitmap::FIFExtensionList($fif);
  my $desc  = Win32::GUI::DIBitmap::FIFDescription($fif);
  my $reg   = Win32::GUI::DIBitmap::FIFRegExpr($fif);
  $reg = 'UNDEF' unless defined $reg;
  my $read  = Win32::GUI::DIBitmap::FIFSupportsReading($fif);
  my $write = Win32::GUI::DIBitmap::FIFSupportsWriting($fif);

  print "$i : Format = $format FIF = $fif Extention = $ext Description = $desc RegExp = $reg Reading = $read Writing = $write\n";
}



my $dib = new Win32::GUI::DIBitmap (100,100,24,255,255,255);

for (my $i = 0; $i < $count; $i++) {

  my ($ext, $misc) = split /,/, Win32::GUI::DIBitmap::FIFExtensionList($i), 2;
  my $f = "res$i.$ext";

  my $res = $dib->SaveToFile($f, $i);
  print "save $f = $res\n";
  unlink $f;
}



