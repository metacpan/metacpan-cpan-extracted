#!/usr/bin/perl
# $Id: Makefile.PL 7377 2012-04-11 10:57:51Z chris $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'WebService::Flixster',
    VERSION_FROM    => 'lib/WebService/Flixster.pm', 
    ABSTRACT_FROM   => 'lib/WebService/Flixster.pm', 
    AUTHOR          => 'Christopher Key <christopher.key@cantab.net>', 
    LICENSE         => 'perl', 
    PREREQ_PM       => {
	'Class::Accessor' => 0, 
	'Cache::FileCache' => 0, 
	'DateTime::Format::Duration' => 0, 
	'DateTime::Incomplete' => 0, 
	'File::Spec::Functions' => 0, 
	'HTML::Entities' => 0,
	'JSON' => 0, 
	'LWP::UserAgent' => 0, 
	'Math::Currency' => 0, 
	'URI' => 0, 
    }, 
    );
