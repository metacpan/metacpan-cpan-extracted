#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Scraper::ISBN::ISBNdb_Driver',
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Scraper/ISBN/ISBNdb_Driver.pm',
    ABSTRACT            => 'Search driver for the isbndb.com online book catalog',
    LICENSE             => 'artistic_2',
    PL_FILES            => {},
    NO_META             => 1,
    PREREQ_PM => {

        # Business::ISBN v2.01 or greater is required for isbn-13 support
        'IO::File'                      => '0',
        'LWP::UserAgent'                => '0',
        'WWW::Scraper::ISBN'            => '1.00',
        'WWW::Scraper::ISBN::Driver'    => '1.00',
        'XML::DOM'                      => '0',
        'XML::LibXML'                   => '0',
        
        # build/test prereqs
        'Data::Dumper'                  => '0',
        'Test::More'                    => '0.70'

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Scraper-ISBN-ISBNdb_Driver-*' },
);
