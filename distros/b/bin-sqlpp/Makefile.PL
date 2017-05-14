# $Id: Makefile.PL,v 1.3 2007/03/24 12:22:30 dk Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'		=> 'bin::sqlpp',
	'VERSION_FROM'	=> 'bin/sqlpp', 
	'dist'		=> {
		COMPRESS => 'gzip -9f',
		SUFFIX   => '.gz', 
		DIST_DEFAULT => 'all tardist',
	},
	'DISTNAME'	=> 'bin-sqlpp',
	'EXE_FILES'	=> ['bin/sqlpp'],
	'ABSTRACT'	=> 'cpp-like SQL preprocessor',
	'AUTHOR'	=> 'Dmitry Karasik <dmitry@karasik.eu.org>',
);
