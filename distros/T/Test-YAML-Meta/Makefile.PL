#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Test::YAML::Meta',
    VERSION_FROM        => 'lib/Test/YAML/Meta.pm',
    ABSTRACT            => 'Validate your CPAN META.yml files',
    NO_META             => 1,
    PREREQ_PM => {

        # prereqs
		'Test::Builder'             => 0,
        'Test::CPAN::Meta::YAML'    => 0.17,
		'Test::YAML::Valid'	        => 0.03,

        # for testing
        'IO::File'                  => 0,       # for testing
        'Test::More'                => 0.70     # for testing

    },
);
