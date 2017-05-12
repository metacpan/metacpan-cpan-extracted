use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Stickam::API',
    AUTHOR              => 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>',
    VERSION_FROM        => 'lib/WWW/Stickam/API.pm',
    ABSTRACT_FROM       => 'lib/WWW/Stickam/API.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'XML::Simple'           => 0,
        'Class::Accessor::Fast' => 0,
        'UNIVERSAL::require'    => 0,
        'JSON::XS'              => 0,
        'LWP::UserAgent'        => 0,
        'URI'                   => 0,
        'Time::HiRes'           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Stickam-API-*' },
);
