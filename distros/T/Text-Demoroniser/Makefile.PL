#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Text::Demoroniser',
    VERSION_FROM        => 'lib/Text/Demoroniser.pm',
    ABSTRACT            => 'A text filter that allows you to demoronise a string',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Encode::ZapCP1252' => 0,

        # build/test prereqs
        'Test::More'        => '0.70',
        'IO::File'          => '0'

    }
);
