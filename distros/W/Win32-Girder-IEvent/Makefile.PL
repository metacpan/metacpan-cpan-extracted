require 5.6.0;

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Win32::Girder::IEvent',
    'VERSION'		=> 0.04,
    'PREREQ_PM'		=> {
	'Digest::MD5'       => 2.00,
	'IO::Socket::INET'  => 1.25,
    },
    'ABSTRACT'      => 'Interface to the Girder Internet Events API',
    'AUTHOR'        => 'Gavin Brock <gbrock@cpan.org>',
    'dist'          => { COMPRESS=>'gzip', SUFFIX=>'gz' },
);
