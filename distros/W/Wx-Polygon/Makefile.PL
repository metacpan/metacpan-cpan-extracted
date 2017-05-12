#############################################################################
## Name:        Makefile.PL
## Purpose:     Makefile
## Author:      Hans Oesterholt-Dijkema
## Modified by:
## Created:     19-4-2004
## RCS-ID:      $Id: Makefile.PL,v 1.4 2004/04/19 19:01:00 cvs Exp $
## Copyright:   (c) 2004 Hans Oesterholt-Dijkema
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under Artistic license.
#############################################################################

use strict;

my $r=eval("use Wx::build::MakeMaker 0.16;return 1;");
if (not $r) {
  die "wxPerl is a prerequisite for this module\n".
      "Please install Wx-0.16 or above\n";
}

use Config;

if ($Config{'osname'} eq "MSWin32") {
  my $w=$ENV{'WXDIR'}.$ENV{'WXWIN'}."";
  if ($w eq "") {
    die "You need to let the environment variables WXDIR and WXWIN\n".
        "point to the compiled source tree of wxWindows. E.g.:\n".
	"\n".
	"   set WXWIN=c:\\devel\\wx\\wxMSW-2.4.2\n".
	"   set WXDIR=c:\\devel\\wx\\wxMSW-2.4.2\n".
	"\n";
  }
}

wxWriteMakefile( NAME         => 'Wx::Polygon',
                 VERSION_FROM => 'Polygon.pm',
                 LIBS         => ( '' ),
                 WX_CORE_LIB  => ( 'core base' ),
               );


