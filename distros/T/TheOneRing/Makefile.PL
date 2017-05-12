#!/usr/bin/perl
# Copyright (C) 2007-2009 Wes Hardaker
# License: GNU GPLv2.  See the COPYING file for details.

use ExtUtils::MakeMaker;

%opts = (
	 'NAME'		=> 'TheOneRing',
	 'EXE_FILES'    => [qw(or)],
	 'VERSION_FROM' => 'or',
	);

WriteMakefile(%opts);
