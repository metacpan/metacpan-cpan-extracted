# -*-Perl-*-
# $Id: Makefile.PL,v 1.17 2004/09/23 09:28:45 mpeppler Exp $
#
#	@(#)Makefile.PL	1.13	03/26/99

require 5.002;

use strict;
use ExtUtils::MakeMaker;

require '../util/config.pl';

my $sattr = &config();

my $DBLIBVS = $$sattr{DBLIBVS};

#####
### Configure End
#####


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
    WriteMakefile('NAME' => "Sybase::Sybperl",
		  'VERSION' => $$sattr{VERSION},
		  ($] >= 5.005 ?
		   (ABSTRACT   => 'Sybperl 1.xx compatibility module',
		    AUTHOR     => 'Michael Peppler (mpeppler@peppler.org)') : ()),
		  ($] >= 5.005 && $^O eq 'MSWin32' && 
		   $Config{archname} =~ /-object\b/i ? (CAPI => 'TRUE') :()),
		  'NEEDS_LINKING' => 1,
		  );
}


