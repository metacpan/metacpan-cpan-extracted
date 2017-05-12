#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME				=> 'MockClass',
			  DISTNAME			=> 'Test-MockClass',
			  VERSION_FROM		=> 'lib/Test/MockClass.pm',
			  AUTHOR			=> 'Jeremiah Jordan <jjordan@perlreason.com>',
			  ABSTRACT			=> 'A class to create mock classes and object for testing purposes',
			  PREREQ_PM			=> {
							   	'Hook::WrapSub'		=> 0.03,
								'Scalar::Util'	   	=> 1.14,
								'Task::Weaken'		=> 0,
								'Test::SimpleUnit'	=> 1.21,
								'Tie::Watch'		=> 1.1,
						   },
			  dist			=> {
								TARFLAGS	=> 'cvf',
								CI		=> "cvs commit",
								RCS_LABEL	=> 'cvs tag r$(VERSION_SYM)',
								SUFFIX		=> ".gz",
								DIST_CP         => 'ln',
								DIST_DEFAULT	=> 'all tardist',
								COMPRESS	=> "gzip",
							   },
			  clean			=> { FILES	=> "*.tar.bz2 *.tar.gz" },
			 );
