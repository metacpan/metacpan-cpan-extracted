# -*-mode: perl; fill-column: 80; comment-column: 80; -*-

# Makefile.PL--
#
#       This file provides out of bounds mechanics.
#
# Copyright (c) 2000-2007 Meccanomania
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# svn: @(#) $Id: Makefile.PL 198 2008-01-26 11:29:11Z meccanomania $
#-------------------------------------------------------------------------------


use ExtUtils::MakeMaker;

#VERSION = '$Revision: 198 $';

WriteMakefile(
	NAME            => 'Tk::Bounded',
	VERSION		=> '1.0.2',
	PREREQ_PM	=> { Tk => '5.8.7', attributes => 0, Carp => 0 },
	);
