use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'WWW::Scraper::ISBN::ISBNnu_Driver',
    VERSION_FROM        => 'lib/WWW/Scraper/ISBN/ISBNnu_Driver.pm',
    ABSTRACT            => 'Search driver for the isbn.nu online book catalog',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'WWW::Mechanize'                => '1.60',
        'WWW::Scraper::ISBN'            => '1.00',
        'WWW::Scraper::ISBN::Driver'    => '1.00',

        # build/test prereqs
        'Data::Dumper'                  => '0',
        'IO::File'                      => '0',
        'Test::More'                    => '0.70'

    }
);
