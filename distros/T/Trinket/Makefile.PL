#!/usr/bin/perl
###########################################################################
### Makefile.PL
### L.M.Orchard (deus_x@pobox.com)
###
### $Id: Makefile.PL,v 1.1.1.1 2001/02/15 18:47:50 deus_x Exp $
###
### TODO:
###
###########################################################################

#use lib "packages";
use ExtUtils::MakeMaker;
use File::Path;
use strict;

my $pkg_name  = 'Trinket';
my $dist_name = 'Trinket';
my $version   = '0.0.1';
my $author    = 'Leslie Michael Orchard';
my $prereqs   =
  {
#    'BerkeleyDB'   => 0,
   'Bit::Vector'  => 0,
  };
my $packages = "./lib";

WriteMakefile
	(
	 'AUTHOR'      => $author,
	 'NAME'	       => $pkg_name,
	 'DISTNAME'    => $dist_name,
	 'VERSION'     => $version,
	 'PREREQ_PM'   => $prereqs,
#	 'INST_LIB'    => 'lib',
#	 'clean' => { FILES => "packages/Iaido/InstallCache.pm" },
	);

__END__
