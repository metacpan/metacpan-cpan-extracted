#!/usr/bin/perl -w

# No Scalar::Util weaken before 5.006
require 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Weaken',
    AUTHOR              => 'Jeffrey Kegler <nospam@no.spam>',
    VERSION_FROM        => 'lib/Test/Weaken.pm',
    ABSTRACT_FROM       => 'lib/Test/Weaken.pm',
    PL_FILES            => {},
    LICENSE             => 'perl',
    MIN_PERL_VERSION    => '5.006',

    PREREQ_PM => {
        'Test::More' => 0,
        'Scalar::Util' => '1.18',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    # clean               => { FILES => 'Test-Weaken-*' },
    SIGN                => 1,

    META_MERGE =>
    { no_index => { directory=>['sandbox'],
                  },
    },
);
