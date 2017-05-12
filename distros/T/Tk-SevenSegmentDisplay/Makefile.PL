#*** Makefile.PL ***#
# Copyright (C) 2009 by Torsten Knorr
# create-soft@freenet.de
# All rights reserved!
#-------------------------------------------------
 use ExtUtils::MakeMaker;
#-------------------------------------------------
 WriteMakefile(
 	NAME	=> 'Tk::SevenSegmentDisplay',
 	VERSION_FROM	=> 'lib/Tk/SevenSegmentDisplay.pm',
 	PREREQ_PM	=> {
 		Tk		=> '0',
 		Tk::Frame	=> '0'
 		},
 	($] >= 5.005 ?
		(ABSTRACT_FROM  => 'lib/Tk/SevenSegmentDisplay.pm',
 		AUTHOR	=> 'Torsten Knorr <create-soft@freenet.de>') : ()),
 	);
#-------------------------------------------------



