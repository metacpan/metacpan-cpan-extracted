#------------------------------------------------------------------------------#
#  Win32::Printer Maker                                                        #
#  Edgars Binans                                                               #
#------------------------------------------------------------------------------#

use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;
use Config;

my ($inc, $lib, $lin, $ccf) = ("", "", "", "");

if ($#ARGV != -1) {

  print "Inlude FreeImage image support? [y]: ";
  my $in = "y";
  $in = <STDIN>;
  if ($in !~ /n/) {
    $inc = '-I.\3PLibs\FreeImage ';
    $lib = '-l.\3PLibs\FreeImage\FreeImage.lib ';
    $lin = '-delayload:FreeImage.dll ';
    $ccf = '-DFREE ';
  }

  print "Inlude Ghostscript PDF support? [y]: ";
  $in = "y";
  $in = <STDIN>;
  if ($in !~ /n/) {
    $inc .= '-I.\3PLibs\Ghostscript ';
    $lib .= '-l.\3PLibs\Ghostscript\gsdll32.lib ';
    $lin .= '-delayload:gsdll32.dll ';
    $ccf .= '-DGHOST ';
    print "\nDO NOT FORGET TO SET A Postscript PRINTER AS DEFAULT FOR THE TESTS TO SUCCEED!\n\n";
  }

  print "Inlude ebbl barcode support? [y]: ";
  $in = "y";
  $in = <STDIN>;
  if ($in !~ /n/) {
    $inc .= '-I.\3PLibs\ebbl';
    $lib .= '-l.\3PLibs\ebbl\ebbl11vc.lib';
    $lin .= '-delayload:ebbl11vc.dll';
    $ccf .= '-DEBBL -DWIN_IMPORT';
  }

} else {

  print "\nDEFAULT BUILD OPTIONS - W/O 3PLibs (SET ANY ARGUMENT TO INVOKE THE PROMPT!)\n\n";

}

WriteMakefile( 
  'NAME'		=> 'Win32::Printer',
  'VERSION_FROM'	=> 'Printer.pm',
  'ABSTRACT_FROM'	=> 'Printer.pm',
  'AUTHOR'		=> 'Edgars Binans',
  'INC'			=>  $inc,
  'LIBS'		=>  "Delayimp.lib $lib",
  'LDDLFLAGS'		=>  "$Config{lddlflags} $lin",
  'CCCDLFLAGS'		=>  $ccf
);
