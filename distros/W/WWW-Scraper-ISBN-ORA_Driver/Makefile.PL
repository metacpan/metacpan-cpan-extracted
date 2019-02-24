#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'WWW::Scraper::ISBN::ORA_Driver',
    VERSION_FROM        => 'lib/WWW/Scraper/ISBN/ORA_Driver.pm',
    ABSTRACT            => q|Search driver for the O'Reilly & Associates' online catalog|,
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'WWW::Mechanize'                => '1.60',
        'WWW::Scraper::ISBN'            => '1.00',
        'WWW::Scraper::ISBN::Driver'    => '1.00',

        # build/test prereqs
        'Data::Dumper'                  => '0',
        'Test::More'                    => '0.70',
        'IO::File'                      => '0'

    }
);
