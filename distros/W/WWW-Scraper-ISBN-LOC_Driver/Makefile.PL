#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'WWW-Scraper-ISBN-LOC_Driver',
    VERSION_FROM        => 'lib/WWW/Scraper/ISBN/LOC_Driver.pm',
    ABSTRACT            => q{Search driver for the Library of Congress' online catalog for book information},
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'HTTP::Request::Common'         => '1.19',
        'LWP::UserAgent'                => '2.00',
        'WWW::Scraper::ISBN'            => '1.00',
        'WWW::Scraper::ISBN::Driver'    => '1.00',

        # build/test prereqs
        'Data::Dumper'                  => '0',
        'IO::File'                      => '0',
        'Test::More'                    => '0.70'

    }
);
