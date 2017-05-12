use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TiVo::Calypso',
    ABSTRACT            => 'A Perl interface to the TiVo Calypso protocol',
    AUTHOR              => 'Scott Schneider <sschneid@gmail.com>',
    VERSION_FROM        => 'lib/TiVo/Calypso.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Storable'      => 0,
        'IO::File'      => 0,
        'MP3::Info'     => 0,
        'Digest::MD5'   => 0,
        'Encode'        => 0,
        'LWP::Simple'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TiVo-Calypso-*' },
);

