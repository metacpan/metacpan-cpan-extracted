#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'constant::tiny',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/constant/tiny.pm',
    ABSTRACT_FROM       => 'lib/constant/tiny.pm',
    PREREQ_PM => {
        # prereqs

        # build/test prereqs
        'Test::More'        => 0,
    },
    META_MERGE          => {
        resources       => {
            repository  => "https://github.com/maddingue/constant-tiny",
            #{
            #    type    => "git",
            #    url     => "git://github.com/maddingue/constant-tiny.git",
            #    web     => "https://github.com/maddingue/constant-tiny",
            #}
        },
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'constant-tiny-*' },
);
