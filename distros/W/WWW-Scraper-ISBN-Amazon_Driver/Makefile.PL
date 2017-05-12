#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'WWW::Scraper::ISBN::Amazon_Driver',
    VERSION_FROM        => 'lib/WWW/Scraper/ISBN/AmazonUS_Driver.pm',
    ABSTRACT            => 'Search drivers for the Amazon online catalog',
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
