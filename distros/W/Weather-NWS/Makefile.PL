use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Weather::NWS',
    AUTHOR       => 'Josh McAdams <josh dot mcadams at gmail dot com>',
    VERSION_FROM => 'lib/Weather/NWS/NDFDgen.pm',
    ABSTRACT     => 'Interface to NWS Web Services',
    PL_FILES     => {},
    PREREQ_PM    => {
        'Test::Pod'           => 1.14,
        'Test::Pod::Coverage' => 1.04,
        'Class::Std'          => 0,
        'Readonly'            => 0,
        'SOAP::DateTime'      => 0,
        'LWP::Simple'         => 0,
        'Test::More'          => 0,
        'warnings'            => 0,
        'strict'              => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Weather-NWS-*' },
);
