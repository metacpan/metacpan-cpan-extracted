#!perl -w
use strict;
use warnings;
use ExtUtils::MakeMaker;

# $Id: ConstantsRC.PL,v 1.1 2006/05/13 15:39:30 robertemay Exp $
# perl script to produce the RC file for
# Win32::GUI::Constants:  create Resource
# file with a VERSIONINFO section

# The variables:
my %info = (
    Version => MM->parse_version('Constants.pm'),
    Dllname => 'Constants.dll',
    Years   => '2006',
    Win32GUIVersion => MM->parse_version('../GUI.pm'),
);

# Open the target file
if ( @ARGV > 0 ) {
    my $file = $ARGV[0];
    open(my $fh, '>', $file) or die qq(Failed to open '$file': $!);
    select $fh;
}

{
    my $fileVersion = $info{Version};
    $fileVersion .= "_00" unless $fileVersion =~ m/_/;
    $info{FileVersion} =
        sprintf("%02d,%02d,%02d,00", $fileVersion =~ m/^(.*)\.([^_]*)_?(.*)$/);
    my $prodVersion = $info{Win32GUIVersion};
    $prodVersion .= "_00" unless $prodVersion =~ m/_/;
    $info{ProductVersion} =
        sprintf("%02d,%02d,%02d,00", $prodVersion =~ m/^(.*)\.([^_]*)_?(.*)$/);
}

print <<"__RC";
#include "winver.h"

1 VERSIONINFO
FILEVERSION    $info{FileVersion}
PRODUCTVERSION $info{ProductVersion}
FILEOS         VOS__WINDOWS32
FILETYPE       VFT_DLL
{
  BLOCK "StringFileInfo"
  {
    BLOCK "040904E4"
    {
      VALUE "Comments"         , "Win32::GUI::Constants, part of the perl Win32::GUI module."
      VALUE "CompanyName"      , "perl-win32-gui.sourceforge.net"
      VALUE "FileDescription"  , "Win32::GUI::Constants perl extension"
      VALUE "FileVersion"      , "$info{Version}"
      VALUE "InternalName"     , "$info{Dllname}"
      VALUE "LegalCopyright"   , "Copyright © Robert May $info{Years}"
      VALUE "LegalTrademarks"  , "GNU and Artistic licences"
      VALUE "OriginalFilename" , "$info{Dllname}"
      VALUE "ProductName"      , "Win32::GUI perl extension"
      VALUE "ProductVersion"   , "$info{Win32GUIVersion}"
    }
  }

  BLOCK "VarFileInfo"
  {
    VALUE "Translation", 0x0409, 0x04E4
  }
}
__RC

exit(0);
__END__
