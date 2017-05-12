#	 $Id: Makefile.PL,v 1.4 2003-03-18 01:04:23-05 hiroo Exp $
#
#	 Copyright (c) 2002 Hiroo Hayashi.  All rights reserved.
#
#	 This program is free software; you can redistribute it and/or
#	 modify it under the same terms as Perl itself.

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Win32API::MIDI',
    'VERSION_FROM'	=> 'MIDI.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MIDI.pm', # retrieve abstract from module
       AUTHOR     => 'Hiroo Hayashi <hiroo.hayashi@computer.org>') : ()),
    'LIBS'		=> ($^O =~ /cygwin/i ?
			    ['-L/usr/lib/w32api -lwinmm'] : []), # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
