# $Id: Makefile.PL,v 1.5 2003/08/18 17:04:41 matt Exp $

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'XML::Generator::DBI',
    'VERSION_FROM' => 'DBI.pm', # finds $VERSION
    'PREREQ_PM' => {
        'MIME::Base64' => 2.00,
        'XML::SAX::Base' => 1.00,
        'Test::More' => 0,
    },
    'ABSTRACT_FROM' => 'DBI.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);
