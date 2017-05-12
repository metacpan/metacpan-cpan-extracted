#!/usr/bin/perl

# $Id: Makefile.PL 23 2007-07-06 20:00:44Z swined $

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Bugzilla3',
    AUTHOR              => 'Alexey Alexandrov <swined@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Bugzilla3.pm',
    ABSTRACT_FROM       => 'lib/WWW/Bugzilla3.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Carp' => 0,
	'RPC::XML' => 0,
	'RPC::XML::Parser' => 0,
	'LWP::UserAgent' => 0,
	'HTTP::Cookies' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Bugzilla3-*' },
);
