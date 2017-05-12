#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'WWW-Scraper-ISBN-OpenLibrary_Driver',
    VERSION_FROM        => 'lib/WWW/Scraper/ISBN/OpenLibrary_Driver.pm',
    ABSTRACT            => 'Search driver for the OpenLibrary online book catalog',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'JSON'                          => '0',
        'WWW::Mechanize'                => '1.60',
        'WWW::Scraper::ISBN'            => '1.00',
        'WWW::Scraper::ISBN::Driver'    => '1.00',

        # build/test prereqs
        'Data::Dumper'                  => '0',
        'IO::File'                      => '0',
        'Test::More'                    => '0.70'

    }
);
