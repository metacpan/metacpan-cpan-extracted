#!/usr/bin/perl
use ExtUtils::MakeMaker;

#------------------------------------------------------------
# Makefile:
#------------------------------------------------------------

# Write the Makefile:
WriteMakefile(
	      NAME         => 'Text::Refer',
	      VERSION_FROM => "./lib/Text/Refer.pm",
	      DISTNAME     => "Text-Refer",
	      EXE_FILES    => [@EXES],
	      'dist'       => {
		  PREOP    => "cd docs ; make",
		  COMPRESS => 'gzip',
		  SUFFIX   => 'gz',
	      }
	      );

