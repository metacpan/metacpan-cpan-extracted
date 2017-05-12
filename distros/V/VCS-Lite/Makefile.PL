#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'VCS::Lite',
    VERSION_FROM        => 'lib/VCS/Lite.pm',
    ABSTRACT            => 'A minimal version control system',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Algorithm::Diff'   => '1.13',
        'Carp'              => '0',

        'Getopt::Long'      => '0', # required by installed scripts

        # build/test prereqs
        'IO::File'          => '0',
        'Test::More'        => '0.70'

    },

    EXE_FILES		=> [qw(scripts/vldiff scripts/vlpatch scripts/vlmerge)]
);
