#! /usr/local/bin/perl -w # -*- perl -*-

# vim: tabstop=4

# Makefile generator for libintl-perl.
# Copyright (C) 2002-2015 Guido Flohr <guido.flohr@cantanea.com>, 
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.
                                                                                
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
                                                                                
# You should have received a copy of the GNU Library General Public 
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, 
# USA.

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME		    => 'simplecal',
    VERSION_FROM	=> 'bin/simplecal.pl',
    PREREQ_PM	    => {
							Locale::TextDomain => 0,
						},
	EXE_FILES		=> [ 'bin/simplecal.pl' ],
	AUTHOR          => 'Guido Flohr <guido.flohr@cantanea.com>',
    ABSTRACT        => 'Demonstration package for libintl-perl',
);

__END__

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
cperl-indent-level: 4
cperl-continued-statement-offset: 2
tab-width: 4
End:
