# $Id: Makefile.PL,v 1.3 2003/12/27 01:33:12 mpeppler Exp $
# from	@(#)Makefile.PL	1.7	03/26/99

require 5.002;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile('NAME' => "Sybase::BLK",
	      'VERSION_FROM' => 'BLK.pm',
	      ($] >= 5.005 ?
	       (ABSTRACT   => 'Sybase Bulk-Copy modules',
		AUTHOR     => 'Michael Peppler (mpeppler@peppler.org)') : ()),
	      ($] >= 5.005 && $^O eq 'MSWin32' && 
	       $Config{archname} =~ /-object\b/i ? (CAPI => 'TRUE') :()),
	      'NEEDS_LINKING' => 1,
	      'dist' => {'TARFLAGS' => "cvfF", 'COMPRESS' => "gzip"},
	     );

