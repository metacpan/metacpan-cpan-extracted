# $Id: Makefile.PL,v 1.3 2003/12/27 01:33:12 mpeppler Exp $
# from	@(#)Makefile.PL	1.7	03/26/99

require 5.002;
use strict;

use ExtUtils::MakeMaker;

require '../util/config.pl';

my $sattr = config();

my $DBLIBVS = $$sattr{DBLIBVS};    

# Write a dummy makefile if DBLIBVS is 0 - this means that we don't have
# DBlibrary on this system...
if($DBLIBVS == 0)
{
    open(MF, ">Makefile") || die "Can't open Makefile: $!";
    print MF "# Empty Makefile to keep make happy\n\nall:\n\nconfig:\n\ntest:\n\ninstall:\n\n";
    print MF "clean realclean:\n	mv Makefile Makefile.old\n";
    close(MF);
}
else
{
    WriteMakefile('NAME' => "Sybase::BCP",
		  'VERSION_FROM' => 'BCP.pm',
		  ($] >= 5.005 ?
		   (ABSTRACT   => 'Sybase Bulk-Copy modules',
		    AUTHOR     => 'Michael Peppler (mpeppler@peppler.org)') : ()),
		  ($] >= 5.005 && $^O eq 'MSWin32' && 
		   $Config{archname} =~ /-object\b/i ? (CAPI => 'TRUE') :()),
		  'NEEDS_LINKING' => 1,
		  'dist' => {'TARFLAGS' => "cvfF", 'COMPRESS' => "gzip"},
		  );
}
