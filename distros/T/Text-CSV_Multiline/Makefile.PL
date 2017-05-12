#!/usr/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Text::CSV_Multiline',
	VERSION           => '0.02',
	PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	ABSTRACT_FROM  => 'lib/Text/CSV_Multiline.pm',
	AUTHOR         => 'Jason Long <jlong@messiah.edu>',
);
