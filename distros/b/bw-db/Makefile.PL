#
# Makefile.PL for BW::DB
# by Bill Weinman (http://bw.org/)
# Copyright 1995-2010 The BearHeart Group, LLC
#

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'              => 'bw-db',
    'AUTHOR'            => 'Bill Weinman (http://bw.org/)',
    'VERSION_FROM'      => 'lib/BW/DB.pm',
    'PREREQ_PM'         => {
        'DBI'               => '1.52',
        'Digest::MD5'       => '0',
        'BW::Base'          => '0',
        'BW::Constants'     => '0'
    }
);

