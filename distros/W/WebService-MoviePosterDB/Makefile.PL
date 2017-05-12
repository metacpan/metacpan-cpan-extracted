#!/usr/bin/perl
# $Id: Makefile.PL 4642 2010-03-09 17:58:39Z chris $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'WebService::MoviePosterDB',
    VERSION_FROM    => 'lib/WebService/MoviePosterDB.pm', 
    ABSTRACT_FROM   => 'lib/WebService/MoviePosterDB.pm', 
    AUTHOR          => 'Christopher Key <cjk32@cam.ac.uk>', 
    LICENSE         => 'perl', 
    PREREQ_PM       => {
	'Class::Accessor' => 0, 
	'Cache::FileCache' => 0, 
	'Digest::MD5' => 0, 
	'File::Spec::Functions' => 0, 
	'JSON' => 0, 
	'LWP::UserAgent' => 0, 
	'URI' => 0, 
    }, 
    );
