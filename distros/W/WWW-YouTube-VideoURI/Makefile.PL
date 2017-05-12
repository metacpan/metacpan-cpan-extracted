#!/usr/bin/perl
# $Id: Makefile.PL,v 1.1 2007/08/29 17:35:11 gavin Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'WWW::YouTube::VideoURI',
    'VERSION_FROM'	=> 'VideoURI.pm',
    'PREREQ_FATAL'	=> 1,
    'PREREQ_PM'		=> {
        Carp			=> 0,
        HTTP::Request::Common	=> 0,
        LWP			=> 0,
        URI			=> 0,
        URI::Escape		=> 0,
    },
);
