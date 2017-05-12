#!/usr/bin/perl
# $Id: Makefile.PL 6313 2011-02-28 11:38:48Z chris $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'WebService::IMDB',
    VERSION_FROM    => 'lib/WebService/IMDB.pm', 
    ABSTRACT_FROM   => 'lib/WebService/IMDB.pm', 
    AUTHOR          => 'Christopher Key <cjk32@cam.ac.uk>', 
    LICENSE         => 'perl', 
    PREREQ_PM       => {
	'Class::Accessor' => 0, 
	'Cache::FileCache' => 0, 
	'DateTime' => 0,
	'DateTime::Duration' => 0,
	'DateTime::Format::Strptime' => 0, 
	'DateTime::Incomplete' => 0,
	'File::Spec::Functions' => 0, 
	'JSON' => 0, 
	'LWP::UserAgent' => 0, 
	'URI' => 0, 
    }, 
    );
