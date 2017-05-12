#! /usr/local/bin/perl -w

# vim: tabstop=4
# $Id: Makefile.PL,v 1.11 2006/05/12 12:42:14 guido Exp $

# Makefile generator for Test-Unit-GTestRunner.
# Copyright (C) 2004-2006 Guido Flohr <guido@imperia.net>, 
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

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME		    => 'Test-Unit-GTestRunner',
	VERSION_FROM	=> 'lib/Test/Unit/GTestRunner.pm',
	EXE_FILES		=> [ 'bin/gtestrunner' ],
    ($] >= 5.005 ?
		(ABSTRACT	=> 'Gtk+ Based Unit Test Runner for Perl',
	 	 AUTHOR		=> 'Guido Flohr <guido@imperia.net>',
		 ) : (),
	),
	PREREQ_PM		=> { 
		Locale::TextDomain => 1.16,
		Gtk2 => 0,
		Gtk2::GladeXML => 0,
	    Test::Unit => 0,
	},
	PL_FILES        => {},
	LICENSE			=> 'gpl',
    (MM->can ('signature_target') ? (SIGN => 1) : ()),

    # This will trigger a warning with ExtUtils::MakeMaker < 6.30_01 :-(
    # Thanks to Graham Barr for the hint.
    EXTRA_META => <<EOF,
no_index:
    dir:
        - Suites
EOF
);

sub MY::postamble {
	'
all :: lib/Test/Unit/GTestRunner.pm Credits ReleaseNotes

lib/Test/Unit/GTestRunner.pm: GTestRunner.pm.in gtestrunner.glade
		cat GTestRunner.pm.in gtestrunner.glade >$@

# Make search.cpan.org happy but still follow GNU standards:
# (Thanks to Graham Barr for the hint)
Credits: THANKS
	cat THANKS >$@

ReleaseNotes: NEWS
	cat NEWS >$@
'
}

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
